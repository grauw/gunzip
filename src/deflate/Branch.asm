;
; Huffman tree node
;
Branch_ID: equ 0CBH  ; First byte of a branch object, for ID purposes

Branch: MACRO
	; ix = reader
	Process:
		Reader_ReadBitInline
		jp nc,0
	zero: equ $ - 2
		jp 0
	one: equ $ - 2
	_size:
	ENDM

Branch_template: Branch
