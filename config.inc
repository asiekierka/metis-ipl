; Configuration

; Reset all I/O ports, including those which have a stable power-on state.
; This is useful for working around initialization issues in inaccurate emulators.
%define FEATURE_FULL_PORT_RESET

; Emulate a bug in the "mono" WS IPL where bank registers $C2/$C3 are not set to 0xFF.
%ifdef TARGET_WS
; %define BUG_NO_RESET_BANK
%endif

; Validate footer bytes 0x0 and 0x5.
%define FEATURE_VALIDATE_FOOTER

; Write protect EEPROM, if not disabled by the cartridge.
%define FEATURE_EEPROM_WRITE_PROTECT
