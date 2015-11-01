;
; Huffman tree node
;
Branch: MACRO
	; ix = reader
	Process:
		Reader_ReadBitInline
	jump:
		jp 0
	jumpAddress: equ $ - 2
	_size:
	ENDM

Branch_template: Branch
