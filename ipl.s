%include "ports.inc"

%ifdef TARGET_WS
%define IPL_SIZE 4096
%define TARGET_MONO
%elifdef TARGET_WSC
%define IPL_SIZE 8192
%define TARGET_COLOR
%elifdef TARGET_SC
%define IPL_SIZE 8192
%define TARGET_COLOR
%else
%error Invalid or unspecified target.
%endif

%include "config.inc"

%define BOOT_STUB_OFFSET 0x2000

	bits 16
	cpu 186
	org 0x0000

start:
	xor ax, ax
	out WS_KEY_SCAN_PORT, al

	mov sp, 0x2000

	; TODO: Implement pin strap 0

	; === Self-test validation ===

%ifdef FEATURE_VALIDATE_SELF_TEST
	; Wait ~20ms
	; TODO: Can this be lower?
	mov cx, 4800
self_test_loop:
	in al, WS_SYSTEM_CTRL_PORT
	test al, 0x80
	jnz self_test_pass
	loop self_test_loop
	jmp error_rom_footer
self_test_pass:
%endif

	; === Cartridge configuration ===

%ifndef BUG_NO_RESET_BANK
	mov ax, 0xFFFF
	out 0xC2, ax
%endif
	push 0x3000
	pop ds

	; Read cartridge flags
	mov cl, [0xFFFC]
	and cl, 0x0C
	in al, WS_SYSTEM_CTRL_PORT
	and al, ~0x0C
	or al, cl
	out WS_SYSTEM_CTRL_PORT, al

%ifdef FEATURE_VALIDATE_FOOTER
	; Validate cartridge
	cmp byte [0xFFF0], 0xEA
	jne error_rom_footer
	test byte [0xFFF5], 0x0F
	jnz error_rom_footer
	test byte [0xFFFD], 0xF0
	jnz error_rom_footer
%endif

%ifdef FEATURE_EEPROM_WRITE_PROTECT
	; Write protect EEPROM, if requested
	mov al, [0xFFF9]
	and al, 0x80
	out 0xBE, al
%endif

	push cs
	pop ds

	; Check for pin strap 1
	in al, WS_KEY_SCAN_PORT
	test al, 0x2
	jz no_pinstrap_1
	jmp 0x4000:0x0010
no_pinstrap_1:

	; === System cleanup and exit ===

	; Reset IRAM
%ifdef TARGET_MONO
	mov cx, 0x2000
%else
	mov cx, 0x8000
%endif
	xor ax, ax
	xor di, di
	rep stosw

	; Copy boot stub
	mov si, boot_stub
	mov di, BOOT_STUB_OFFSET
	mov cx, (boot_stub_end - boot_stub)
	rep movsb

	; Reset I/O port state
	mov si, port_reset_table
	mov ah, 0
port_reset_loop:
	lodsb
	cmp al, 0xFF
	je port_reset_loop_end
	mov ax, dx
	mov al, 0
	out dx, al
	jmp port_reset_loop
port_reset_loop_end:

	; Set non-zero ports, enable display
	mov al, WS_LCD_CTRL_DISPLAY_ENABLE
	out WS_LCD_CTRL_PORT, al
%ifdef TARGET_COLOR
%ifdef FEATURE_FULL_PORT_RESET
	mov al, 0x0A
	out WS_SYSTEM_CTRL_COLOR_PORT, al
%endif
%endif

	; Reset CPU register state
%ifdef TARGET_WS
	mov bx, 0x0040
	mov si, 0x023D
	mov di, 0x040D
%else
	mov bx, 0x0043
	mov si, 0x0457
	mov di, 0x040B
%endif
	xor cx, cx
	xor bp, bp

	; Lock out boot ROM, jump to ROM
	mov ax, 0xFF40
	out WS_KEY_SCAN_PORT, ax
	in al, WS_SYSTEM_CTRL_PORT
	or al, WS_SYSTEM_CTRL_IPL_LOCK
	jmp 0x0000:BOOT_STUB_OFFSET

error_rom_footer:
	; TODO
%ifdef TARGET_COLOR
	; Shut down console
	mov al, 0x01
	out WS_SYSTEM_CTRL_COLOR2_PORT, al
	dec al
	out WS_INT_ENABLE_PORT, al
	dec al
	out WS_INT_ACK_PORT, al
	hlt
%else
	jmp error_rom_footer
%endif

boot_stub:
	out WS_SYSTEM_CTRL_PORT, al
	jmp 0xFFFF:0x0000
boot_stub_end:

port_reset_table:
	db 0x07, 0x10, 0x11, 0x12, 0x13, 0x15, 0x80, 0x81, 0x82, 0x83, 0x84,
	db 0x85, 0x86, 0x87, 0x88, 0x89, 0x8A, 0x8B, 0x8C, 0x8F, 0x90, 0x91,
	db 0x94, 0xB0, 0xB2
%ifdef FEATURE_FULL_PORT_RESET
	db 0x00, 0x01, 0x02, 0x04, 0x05, 0x06,
%ifdef TARGET_COLOR
	db 0x40, 0x41, 0x42, 0x44, 0x45, 0x46, 0x47, 0x48
	db 0x4A, 0x4B, 0x4C, 0x4E, 0x4F, 0x50, 0x52
%endif
	db 0x8E, 0x95, 0xA2, 0xA3, 0xB3, 0xB7
%endif
	db 0xFF

	times (IPL_SIZE-16)-($-$$) db 0xFF

	; ROM footer

	jmp ((0x100000-IPL_SIZE)>>4):start

	db 0x00 ; Maintenace
	db 0x00 ; Developer ID
	db 0x00 ; Color
	db 0x00 ; Cart number
	db 0x00 ; Version
	db 0x00 ; ROM size
	db 0x00 ; Save type
	dw 0x0000 ; Flags
	dw 0x0000 ; Checksum
