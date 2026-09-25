// See LICENSE.SiFive for license details.

#include "encoding.h"

// The debugger can assume as second scratch register.
// # define SND_SCRATCH 1
// These are implementation-specific addresses in the Debug Module
#define HALTED    0x100
#define GOING     0x104
#define RESUMING  0x108
#define EXCEPTION 0x10C
#define INTMODE   0x110
#define CAPMODE   0x114

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
        // For CHERI: we always enter in capability pointer
        // mode.

entry:
        jal zero, _entry
resume:
        jal zero, _resume
exception_capmode:
        jal zero, _exception_capmode
exception_intmode:
        jal zero, _exception_intmode
reentry_capmode:
        jal zero, _reentry_capmode
reentry_intmode:
        jal zero, _reentry_intmode

// Common code shared between entry and re-entry cases
#ifdef SND_SCRATCH
#define SETUP                                                                                                  \
        fence                  ; /* This fence is required because the execution may have written something */ \
                                 /* into the Abstract Data or Program Buffer registers.                     */ \
        csrw CSR_DSCRATCH0, s0 ; /* Save s0 to allow signaling MHARTID                                      */ \
        csrw CSR_DSCRATCH1, a0 ; /* Save a0 to allow loading arbitrary DM base                              */ \
        auipc a0, 0            ; /* Get PC                                                                  */ \
        srli a0, a0, 12        ; /* And throw away lower 12 bits to get the DM base                         */ \
        slli a0, a0, 12        ;                                                                               \
        modesw.int
#else
#define SETUP                    /*                                                                         */ \
        fence                  ; /* This fence is required because the execution may have written something */ \
                                 /* into the Abstract Data or Program Buffer registers.                     */ \
        csrw CSR_DSCRATCH0, s0 ; /* Save s0 to allow signaling MHARTID                                      */ \
        modesw.int
#endif

_reentry_capmode:
        SETUP
#ifdef SND_SCRATCH
        sw   s0, CAPMODE(a0)
        add  s0, s0, a0
#else
        sw   s0, CAPMODE(zero)
#endif
        jal zero, entry_loop

_reentry_intmode:
        SETUP
#ifdef SND_SCRATCH
        sw   s0, INTMODE(a0)
        add  s0, s0, a0
#else
        sw   s0, INTMODE(zero)
#endif
        jal zero, entry_loop

_entry:
        SETUP
        // We continue to let the hart know that we are halted in order that
        // a DM which was reset is still made aware that a hart is halted.
        // We keep checking both whether there is something the debugger wants
        // us to do, or whether we should resume.
entry_loop:
        csrr s0, CSR_MHARTID
#ifdef SND_SCRATCH
        sw   s0, HALTED(a0)
        add  s0, s0, a0
#else
        sw   s0, HALTED(zero)
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

_resume:
        modesw.int
        csrr s0, CSR_MHARTID
#ifdef SND_SCRATCH
        sw   s0, RESUMING(a0)    // When Debug Module sees this write, the RESUME flag is reset.
        modesw.cap
        csrr a0, CSR_DSCRATCH1   // Restore a0 here
#else
        sw   s0, RESUMING(zero)  // When Debug Module sees this write, the RESUME flag is reset.
        modesw.cap
#endif
        csrr s0, CSR_DSCRATCH0   // Restore s0 here
        dret


// "Going": code to restore registers and jump to "whereto"

// Common restore code used by intmode and capmode cases
#ifdef SND_SCRATCH
#define RESTORE \
        csrr a0, CSR_DSCRATCH1 ; /* Restore a0 here */ \
        csrr s0, CSR_DSCRATCH0   /* Restore s0 here */
#else
#define RESTORE \
        csrr s0, CSR_DSCRATCH0   /* Restore s0 here */
#endif

_exception_capmode:
        SETUP
        csrr s0, CSR_MHARTID
#ifdef SND_SCRATCH
        sw   s0, EXCEPTION(a0)
#else
        sw   s0, EXCEPTION(zero)
#endif
        modesw.cap
        RESTORE
        ebreak

_exception_intmode:
        SETUP
        csrr s0, CSR_MHARTID
#ifdef SND_SCRATCH
        sw   s0, EXCEPTION(a0)
#else
        sw   s0, EXCEPTION(zero)
#endif
        modesw.cap
        RESTORE
        modesw.int
        ebreak


        // On the restore path, we don't have a safe register to store state, so duplicate
        // the code paths with the different modesw instructions at the end
going:
        // Check the target mode
        csrr s0, mhartid
#ifdef SND_SCRATCH
        add  s0, s0, a0
#endif
        lbu  s0, FLAGS(s0)
        andi s0, s0, (1 << FLAG_INT_MODE)
        modesw.int             //
        sw zero, GOING(a0)     // When debug module sees this write, the GO flag is reset.
        modesw.cap             //
        beqz s0, going_capmode
going_intmode:
        RESTORE
        modesw.int
        jal zero, whereto
going_capmode:
        RESTORE
        jal zero, whereto

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
