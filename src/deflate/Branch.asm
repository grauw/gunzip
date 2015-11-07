;
; Huffman tree node
;
Branch: MACRO
	; ix = reader
	Process:
		Reader_ReadBitInline
	jump:
		jp c,System_ThrowException
	jumpAddress: equ $ - 2
	_size:
	ENDM

Branch_template: Branch
