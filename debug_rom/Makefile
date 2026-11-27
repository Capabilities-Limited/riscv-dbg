# See LICENSE.SiFive for license details

debug_rom = debug_rom.sv

GCC?=clang -target riscv64 -march=rv64y_zyhybrid
OBJCOPY?=llvm-objcopy
OBJDUMP?=llvm-objdump
PYTHON?=python3

all: $(debug_rom)

%.sv: %.img
	$(PYTHON) gen_rom.py $<

%.img: %.bin
	dd if=$< of=$@ bs=256

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

%.elf: $(findstring debug_rom, $(debug_rom)).S link.ld
	$(GCC) -I$(RISCV)/include -Tlink.ld $< -nostdlib -fPIC -static -Wl,--no-gc-sections -o $@

%.dump: %.elf
	$(OBJDUMP) -d $< --disassemble-all --disassemble-zeroes --section=.text --section=.text.startup --section=.text.init --section=.data  > $@

clean:
	rm -f *.img *.dump *.bin *.sv
