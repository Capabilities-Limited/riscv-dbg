// See LICENSE.SiFive for license details.

#include "encoding.h"

// The debugger can assume as second scratch register.
// # define SND_SCRATCH 1
// These are implementation-specific addresses in the Debug Module
#define HALTED    0x100
#define GOING     0x104
#define RESUMING  0x108
#define EXCEPTION 0x10C

// Region of memory where each hart has 1
// byte to read.
#define FLAGS 0x400
#define FLAG_GO     0
#define FLAG_RESUME 1

        .option norvc
        .global entry
        .global exception

        // Entry location on ebreak, Halt, or Breakpoint
        // It is the same for all harts. They branch when
        // their GO or RESUME bit is set.

entry:
        jal zero, _entry
resume:
        jal zero, _resume
exception:
        jal zero, _exception

// Register used to hold base address for DM memory-mapped accesses
#ifdef SND_SCRATCH
#define ADDR_REG a0
#else
#define ADDR_REG zero
#endif

// Macro to save registers
#define SAVE_SINGLE_SCRATCH csrw CSR_DSCRATCH0, s0
#ifdef SND_SCRATCH
#define SAVE SAVE_SINGLE_SCRATCH ; csrw CSR_DSCRATCH1, a0
#else
#define SAVE SAVE_SINGLE_SCRATCH
#endif

// Macro to restore registers saved by SETUP
#define RESTORE_SINGLE_SCRATCH csrr s0, CSR_DSCRATCH0
#ifdef SND_SCRATCH
#define RESTORE RESTORE_SINGLE_SCRATCH ; csrr a0, CSR_DSCRATCH1
#else
#define RESTORE RESTORE_SINGLE_SCRATCH
#endif

// Derive DM base address from PC if required
#ifdef SND_SCRATCH
#define GET_DM_BASE                                                           \
        auipc a0, 0            ; /* Get PC                                 */ \
        srli a0, a0, 12        ; /* And throw away lower 12 bits to get    */ \
                                 /* the DM base                            */ \
        slli a0, a0, 12
#else
#define GET_DM_BASE /* empty */
#endif

// Macro to handle debug entry, saving registers and possibly deriving DM base
#define SETUP                                                                 \
        fence                  ; /* This fence is required because the     */ \
                                 /* execution may have written something   */ \
                                 /* into the Abstract Data or Program      */ \
                                 /* Buffer registers                       */ \
        SAVE                   ; /* Save registers. For CHERI, this needs  */ \
                                 /* to save full capabilities. We assume   */ \
                                 /* we enter the debug ROM in capmode      */ \
        modesw.int             ; /* Switch to int mode for mem accesses    */ \
        GET_DM_BASE


_entry:
        SETUP
        // We continue to let the hart know that we are halted in order that
        // a DM which was reset is still made aware that a hart is halted.
        // We keep checking both whether there is something the debugger wants
        // us to do, or whether we should resume.
entry_loop:
        csrr s0, CSR_MHARTID
        sw   s0, HALTED(ADDR_REG)
#ifdef SND_SCRATCH
        add  s0, s0, a0
#endif
        lbu  s0, FLAGS(s0) // 1 byte flag per hart. Only one hart advances here.
        andi s0, s0, (1 << FLAG_GO)
        bnez s0, going
        csrr s0, CSR_MHARTID
#ifdef SND_SCRATCH
        add  s0, s0, a0
#endif
        lbu  s0, FLAGS(s0) // multiple harts can resume  here
        andi s0, s0, (1 << FLAG_RESUME)
        bnez s0, resume
        jal  zero, entry_loop

_exception:
        // We can only get here due to an exception while in debug mode. Hence,
        // we do not need to save a0 to a scratch register as it has already
        // been saved on debug entry.
        // It is safe to always restore the scratch registers here as they must
        // have been saved on debug entry. Restoring them here avoids issues
        // with registers being overwritten by exceptions occuring during
        // program buffer execution.
        GET_DM_BASE
        sw   zero, EXCEPTION(ADDR_REG) // Let debug module know you got an exception.
        modesw.cap                     // Return to capmode so we restore for capabilities from registers
        RESTORE
        ebreak

going:
        sw zero, GOING(ADDR_REG)       // When debug module sees this write, the GO flag is reset.
        modesw.cap                     // Return to capmode so we restore for capabilities from registers
        RESTORE
        jal zero, whereto

_resume:
        modesw.int
        csrr s0, CSR_MHARTID
        sw   s0, RESUMING(ADDR_REG)    // When Debug Module sees this write, the RESUME flag is reset.
        modesw.cap                     // Return to capmode so we restore for capabilities from registers
        RESTORE
        dret

        // END OF ACTUAL "ROM" CONTENTS. BELOW IS JUST FOR LINKER SCRIPT.

//whereto:
//      nop
        // Variable "ROM" This is : jal x0 abstract, jal x0 program_buffer,
        //                or jal x0 resume, as desired.
        //                Debug Module state machine tracks what is 'desired'.
        //                We don't need/want to use jalr here because all of the
        //                Variable ROM contents are set by
        //                Debug Module before setting the OK_GO byte.
        //                NOTE: this address is assigned as a constant in the
        //                      linker script
