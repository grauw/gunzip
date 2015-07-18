;
; Huffman alphabet
;
Alphabet_MAX_BITLENGTH: equ 16
Alphabet_MAX_CODESET: equ 288

Alphabet: MACRO
	bitCounts:
		ds Alphabet_MAX_BITLENGTH + 1, 0  ; allocate on stack?
	nextCodes:
		ds Alphabet_MAX_BITLENGTH * 2, 0
	codeLengths:
		ds Alphabet_MAX_CODESET, 0
	_size:
	ENDM

Alphabet_class: Class Alphabet, Alphabet_template, Alphabet_Constructor, Alphabet_Destructor, Heap_main
Alphabet_template: Alphabet

; ix = this
; ix <- this
Alphabet_Constructor:
	ret

; ix = this
; ix <- this
Alphabet_Destructor:
	ret

; hl = bit length table (MAX_CODESET entries long)
; ix = this
Alphabet_SetCodeLengths:
	call Alphabet_CountBitLengths
	call Alphabet_CalculateNextCodes
	ret

; hl = bit length table (MAX_CODESET entries long)
; ix = this
Alphabet_CountBitLengths:
	ld bc,2002H  ; 288x
Loop:
	ld a,(hl)
	inc hl
	call Alphabet_CountBitLength
	djnz Loop
	dec c
	jr nz,Loop
	ret

; a = bit length
; ix = this
; Modifies: af, de
Alphabet_CountBitLength:
	cp Alphabet_MAX_BITLENGTH + 1
	call nc,System_ThrowException
	push ix
	add a,Alphabet.bitCounts
	ld e,a
	ld d,0
	add ix,de
	inc (ix)
	pop ix
	ret

; ix = this
Alphabet_CalculateNextCodes: PROC
	push ix
	push ix
	pop iy
	ld hl,0  ; code
	ld b,Alphabet_MAX_BITLENGTH - 1
Loop:
	ld (iy + Alphabet.nextCodes),l
	ld (iy + Alphabet.nextCodes + 1),h
	inc iy
	inc iy
	ld e,(ix + Alphabet.bitCounts + 1)
	ld d,0
	inc ix
	add hl,de
	add hl,hl
	djnz Loop
	ld (iy + Alphabet.nextCodes),l
	ld (iy + Alphabet.nextCodes + 1),h
	pop ix
	ret
	ENDP

;
Alphabet_fixedCodeLengths:
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8  ; 0-144: 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9  ; 144-256: 9
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 7, 7, 7, 7, 7, 7, 7, 7  ; 256-280: 7
	db 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8  ; 280-288: 8
