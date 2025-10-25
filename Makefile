BUILDDIR := build

.PHONY: all clean

all: ipl_aswan.bin ipl_sphinx.bin ipl_sphinx2.bin

ipl_aswan.bin: ipl.s config.inc ports.inc
	@echo "  NASM    $@"
	nasm $< -DTARGET_WS -o $@

ipl_sphinx.bin: ipl.s config.inc ports.inc
	@echo "  NASM    $@"
	nasm $< -DTARGET_WSC -o $@

ipl_sphinx2.bin: ipl.s config.inc ports.inc
	@echo "  NASM    $@"
	nasm $< -DTARGET_SC -o $@

clean:
	@echo "  CLEAN"
	rm -f ipl_aswan.bin ipl_sphinx.bin ipl_sphinx2.bin
