// See LICENSE.SiFive for license details.

#include "encoding.h"

// The debugger can assume as second scratch register.
// These are implementation-specific addresses in the Debug Module
#define HALTED    0x100
#define GOING     0x108
#define RESUMING  0x110
#define EXCEPTION 0x118
#define INTMODE   0x120
#define CAPMODE   0x128

// Region of memory where each hart has 1
// byte to read.
#define FLAGS 0x400
#define FLAG_GO     0
#define FLAG_RESUME 1
#define FLAG_INT_MODE 2

        .option norvc
        .global entry
        .global exception

        // Entry location on ebreak, Halt, or Breakpoint
        // It is the same for all harts. They branch when
        // their GO or RESUME bit is set.
        // For CHERI, we always enter in capmode

entry:
        jal zero, _entry
        nop
resume:
        jal zero, _resume
        nop
exception_capmode:
        jal zero, _exception_capmode
        nop
exception_intmode:
        jal zero, _exception_intmode
        nop
reentry_capmode:
        jal zero, _reentry_capmode
        nop
reentry_intmode:
        jal zero, _reentry_intmode
        nop

// Macro to save registers
#define SAVE                     \
        csrw CSR_DSCRATCH0, s0 ; \
        csrw CSR_DSCRATCH1, a0

// Macro to restore registers saved by SETUP
#define RESTORE                  \
        csrr s0, CSR_DSCRATCH0 ; \
        csrr a0, CSR_DSCRATCH1

// Derive DM base address from PC
#define GET_DM_BASE                                                           \
        auipc a0, 0            ; /* Get PC                                 */ \
        srli a0, a0, 12        ; /* And throw away lower 12 bits to get    */ \
                                 /* the DM base                            */ \
        slli a0, a0, 12

// Macro to handle debug entry, saving registers and possibly deriving DM base
#define SETUP                                                                 \
        fence                  ; /* This fence is required because the     */ \
                                 /* execution may have written something   */ \
                                 /* into the Abstract Data or Program      */ \
                                 /* Buffer registers                       */ \
        SAVE                   ; /* Save registers. For CHERI, this needs  */ \
                                 /* to save full capabilities. We assume   */ \
                                 /* we enter the debug ROM in capmode      */ \
        ymodeswi               ; /* Switch to int mode for mem accesses    */ \
        GET_DM_BASE


_reentry_capmode:
        SETUP
        csrr s0, CSR_MHARTID
        sw s0, CAPMODE(a0) // Save that the progbuf finished in capmode
        jal zero, entry_loop

_reentry_intmode:
        SETUP
        csrr s0, CSR_MHARTID
        sw s0, INTMODE(a0) // Save that the progbuf finished in intmode
        jal zero, entry_loop

_entry:
        SETUP
        // We continue to let the hart know that we are halted in order that
        // a DM which was reset is still made aware that a hart is halted.
        // We keep checking both whether there is something the debugger wants
        // us to do, or whether we should resume.
entry_loop:
        csrr s0, CSR_MHARTID
        sw   s0, HALTED(a0)
        add  s0, s0, a0
        lbu  s0, FLAGS(s0) // 1 byte flag per hart. Only one hart advances here.
        andi s0, s0, (1 << FLAG_GO)
        bnez s0, going
        csrr s0, CSR_MHARTID
        add  s0, s0, a0
        lbu  s0, FLAGS(s0) // multiple harts can resume  here
        andi s0, s0, (1 << FLAG_RESUME)
        bnez s0, resume
        jal  zero, entry_loop

// We can only get exceptions due to an exception while in debug mode.
// Hence, we do not need to save a0 to a scratch register as it has already
// been saved on debug entry.
// It is safe to always restore the scratch registers here as they must
// have been saved on debug entry. Restoring them here avoids issues
// with registers being overwritten by exceptions occuring during
// program buffer execution.
// TODO: I'm not sure about the above as the progbuf might have been using
// the scratch registers: see https://github.com/pulp-platform/riscv-dbg/issues/207
// However, we do have to save whether we finished execution in intmode or capmode.
_exception_capmode:
        ymodeswi                 // Switch to intmode for mem access
        GET_DM_BASE
        sw   zero, EXCEPTION(a0) // Let debug module know you got an exception.
        ymodeswy                 // Return to capmode so we restore for capabilities from registers
        RESTORE
        ebreak                   // Ebreak in capmode to preserve the mode we took exception from

_exception_intmode:
        ymodeswi                 // Switch to intmode for mem access
        GET_DM_BASE
        sw   zero, EXCEPTION(a0) // Let debug module know you got an exception.
        ymodeswy                 // Return to capmode so we restore for capabilities from registers
        RESTORE
        ymodeswi
        ebreak                   // Ebreak in intmode to preserve the mode we took exception from

going:
        sw zero, GOING(a0)       // When debug module sees this write, the GO flag is reset.
        csrr s0, mhartid         // Ask the debug module what the target mode is
        add s0, s0, a0
        lbu s0, FLAGS(s0)
        andi s0, s0, (1 << FLAG_INT_MODE)
        ymodeswy                       // Return to capmode so we restore for capabilities from registers
        beqz s0, going_capmode         // Different codepaths from here for intmode and capmode: there's
                                       // nowhere else to save this information after we restore registers
                                       // (which requires capmode)
going_intmode:
        RESTORE
        ymodeswi
        jal zero, whereto
going_capmode:
        RESTORE
        jal zero, whereto

_resume:
        ymodeswi
        csrr s0, CSR_MHARTID
        sw   s0, RESUMING(a0)  // When Debug Module sees this write, the RESUME flag is reset.
        ymodeswy               // Return to capmode so we restore for capabilities from registers
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
