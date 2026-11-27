/* See LICENSE.SiFive for license details. */
OUTPUT_ARCH( "riscv" )
ENTRY( entry )
SECTIONS
{
    debug_base = 0x0;
    whereto = 0x300;
    . = 0x800;
    .text :
    {
        *(.text)
    }
    _end = .;
}
