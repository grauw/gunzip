;
; The dynamic alphabets
;
HuffmanCodes_MAX_HEADERCODELENGTHS: equ 19
HuffmanCodes_MAX_LITERALLENGTHCODELENGTHS: equ 286
HuffmanCodes_MAX_DISTANCECODELENGTHS: equ 30

HuffmanCodes: MACRO
	hlit:
		db 0  ; we only store the LSB, MSB is always 1
	hdist:
		db 0
	hclen:
		db 0
	codeLengths:
		ds HuffmanCodes_MAX_LITERALLENGTHCODELENGTHS + HuffmanCodes_MAX_DISTANCECODELENGTHS
	headerCodeAlphabet:
		Alphabet
	literalLengthAlphabet:
		Alphabet
	distanceAlphabet:
		Alphabet
	_size:
	ENDM

; hl = literal/length symbol handlers table
; de = distance symbol handlers table
; ix = this
; iy = reader
; ix <- this
HuffmanCodes_Construct:
	push de
	push hl
	call HuffmanCodes_ReadLengths
	call HuffmanCodes_ReadHeaderCodeLengths
	call HuffmanCodes_ConstructHeaderCodeAlphabet
	call HuffmanCodes_ReadLiteralLengthDistanceCodeLengths
	call HuffmanCodes_DestructHeaderCodeAlphabet
	pop hl
	call HuffmanCodes_ConstructLiteralLengthAlphabet
	pop hl
	call HuffmanCodes_ConstructDistanceAlphabet
	ret

; hl = literal/length symbol handlers table
; de = distance symbol handlers table
; ix = this
; ix <- this
HuffmanCodes_ConstructFixed:
	push de
	push ix
	call HuffmanCodes_GetLiteralLengthAlphabet
	ld bc,HuffmanCodes_fixedLiteralLengthCodeLengthsCount
	ld de,HuffmanCodes_fixedLiteralLengthCodeLengths
	call Alphabet_Construct
	pop ix
	pop hl
	push ix
	call HuffmanCodes_GetDistanceAlphabet
	ld bc,HuffmanCodes_fixedDistanceCodeLengthsCount
	ld de,HuffmanCodes_fixedDistanceCodeLengths
	call Alphabet_Construct
	pop ix
	ret

; ix = this
HuffmanCodes_ConstructHeaderCodeAlphabet:
	push ix
	ld hl,HuffmanCodes.codeLengths
	ld e,ixl
	ld d,ixh
	add hl,de
	ld bc,HuffmanCodes_MAX_HEADERCODELENGTHS
	call HuffmanCodes_GetHeaderCodeAlphabet
	ex de,hl
	ld hl,HuffmanCodes_headerCodeSymbols
	call Alphabet_Construct
	pop ix
	ret

; hl = literal/length symbol handlers table
; ix = this
HuffmanCodes_ConstructLiteralLengthAlphabet:
	push ix
	push hl
	ld hl,HuffmanCodes.codeLengths
	ld e,ixl
	ld d,ixh
	add hl,de
	ld c,(ix + HuffmanCodes.hlit)
	ld b,1
	call HuffmanCodes_GetLiteralLengthAlphabet
	ex de,hl
	pop hl
	call Alphabet_Construct
	pop ix
	ret

; hl = distance symbol handlers table
; ix = this
HuffmanCodes_ConstructDistanceAlphabet:
	push ix
	push hl
	ld hl,HuffmanCodes.codeLengths
	ld e,ixl
	ld d,ixh
	add hl,de
	ld e,(ix + HuffmanCodes.hlit)
	ld d,1
	add hl,de
	ld c,(ix + HuffmanCodes.hdist)
	ld b,0
	call HuffmanCodes_GetDistanceAlphabet
	ex de,hl
	pop hl
	call Alphabet_Construct
	pop ix
	ret

; ix = this
; ix <- this
HuffmanCodes_Destruct:
	push ix
	call HuffmanCodes_GetLiteralLengthAlphabet
	call Alphabet_Destruct
	pop ix
	push ix
	call HuffmanCodes_GetDistanceAlphabet
	call Alphabet_Destruct
	pop ix
	ret

; ix = this
HuffmanCodes_DestructHeaderCodeAlphabet:
	push ix
	call HuffmanCodes_GetHeaderCodeAlphabet
	call Alphabet_Destruct
	pop ix
	ret

; ix = this
HuffmanCodes_GetHeaderCodeAlphabet:
	ld de,HuffmanCodes.headerCodeAlphabet
	add ix,de
	ret

; ix = this
HuffmanCodes_GetLiteralLengthAlphabet:
	ld de,HuffmanCodes.literalLengthAlphabet
	add ix,de
	ret

; ix = this
HuffmanCodes_GetDistanceAlphabet:
	ld de,HuffmanCodes.distanceAlphabet
	add ix,de
	ret

; ix = this
; hl <- literal/length alphabet root
; de <- distance alphabet root
HuffmanCodes_GetRoots:
	push ix
	call HuffmanCodes_GetDistanceAlphabet
	ld e,(ix + Alphabet.treeStart)
	ld d,(ix + Alphabet.treeStart + 1)
	pop ix
	push de
	push ix
	call HuffmanCodes_GetLiteralLengthAlphabet
	ld l,(ix + Alphabet.treeStart)
	ld h,(ix + Alphabet.treeStart + 1)
	pop ix
	pop de
	ret

; ix = this
; iy = reader
HuffmanCodes_ReadLengths:
	ld b,5
	call Reader_ReadBits_IY
	inc a
	cp (HuffmanCodes_MAX_LITERALLENGTHCODELENGTHS & 0FFH) + 1
	call nc,System_ThrowException
	ld (ix + HuffmanCodes.hlit),a
	ld b,5
	call Reader_ReadBits_IY
	inc a
	cp HuffmanCodes_MAX_DISTANCECODELENGTHS + 1
	call nc,System_ThrowException
	ld (ix + HuffmanCodes.hdist),a
	ld b,4
	call Reader_ReadBits_IY
	add a,4
	cp HuffmanCodes_MAX_HEADERCODELENGTHS + 1
	call nc,System_ThrowException
	ld (ix + HuffmanCodes.hclen),a
	ret

; ix = this
; iy = reader
HuffmanCodes_ReadHeaderCodeLengths: PROC
	ld hl,HuffmanCodes.codeLengths
	ld e,ixl
	ld d,ixh
	add hl,de
	ld e,l
	ld d,h
	inc de
	ld (hl),0
	ld bc,HuffmanCodes_MAX_HEADERCODELENGTHS - 1
	ldir
	ld b,(ix + HuffmanCodes.hclen)
	ld hl,HuffmanCodes_headerCodeOrder
Loop:
	ld e,(hl)
	ld d,0
	inc hl
	push hl
	push ix
	add ix,de
	push bc
	ld b,3
	call Reader_ReadBits_IY
	pop bc
	ld (ix + HuffmanCodes.codeLengths),a
	pop ix
	pop hl
	djnz Loop
	ret
	ENDP

; ix = this
; iy = reader
HuffmanCodes_ReadLiteralLengthDistanceCodeLengths:
	ld hl,HuffmanCodes.codeLengths
	ld e,ixl
	ld d,ixh
	add hl,de
	ld a,(ix + HuffmanCodes.hlit)
	add a,(ix + HuffmanCodes.hdist)
	push ix
	call HuffmanCodes_GetHeaderCodeAlphabet
	call Alphabet_GetRoot
	ld e,a
	ld d,2  ; +1 for nested 8-bit loop
	call Reader_PrepareReadBitInline_IY
	call HuffmanCodes_DecodeLiteralLengthDistanceCodeLengths
	call Reader_FinishReadBitInline_IY
	pop ix
	ret

; c = inline bit reader state
; de = loop counter for nested 8-bit loop
; hl = literal/length/distance code lengths position
; ix = header code alphabet root
; iy = reader
HuffmanCodes_DecodeLiteralLengthDistanceCodeLengths:
	jp ix

; c = inline bit reader state
; de = loop counter for nested 8-bit loop
; hl = literal/length/distance code lengths position
; ix = header code alphabet root
; iy = reader
HuffmanCodes_WriteAndNext:
	inc hl
	dec e
	jp nz,HuffmanCodes_DecodeLiteralLengthDistanceCodeLengths
	dec d
	jr nz,HuffmanCodes_DecodeLiteralLengthDistanceCodeLengths
	ret

; a = fill value
; b = repeat count
; c = inline bit reader state
; de = loop counter for nested 8-bit loop
; hl = literal/length/distance code lengths position
; ix = header code alphabet root
; iy = reader
HuffmanCodes_FillAndNext_Loop:
	dec b
	jr z,HuffmanCodes_DecodeLiteralLengthDistanceCodeLengths
HuffmanCodes_FillAndNext:
	ld (hl),a
	inc hl
	dec e
	jp nz,HuffmanCodes_FillAndNext_Loop
	dec d
	jr nz,HuffmanCodes_FillAndNext_Loop
	ret

; Header code alphabet symbols 0-15
; c = inline bit reader state
; de = loop counter for nested 8-bit loop
; hl = literal/length/distance code lengths position
; ix = header code alphabet root
; iy = reader
HuffmanCodes_WriteLength: REPT 16, ?value
	ld (hl),?value
	jp HuffmanCodes_WriteAndNext
	ENDM

; Header code alphabet symbols 16
; c = inline bit reader state
; de = loop counter for nested 8-bit loop
; hl = literal/length/distance code lengths position
; ix = header code alphabet root
; iy = reader
HuffmanCodes_Copy:
	call Reader_ReadBitsInline_2_IY
	add a,3
	ld b,a
	dec hl
	ld a,(hl)
	inc hl
	jp HuffmanCodes_FillAndNext

; Header code alphabet symbols 17
; c = inline bit reader state
; de = loop counter for nested 8-bit loop
; hl = literal/length/distance code lengths position
; ix = header code alphabet root
; iy = reader
HuffmanCodes_FillZero_3:
	call Reader_ReadBitsInline_3_IY
	add a,3
	ld b,a
	xor a
	jp HuffmanCodes_FillAndNext

; Header code alphabet symbols 18
; c = inline bit reader state
; de = loop counter for nested 8-bit loop
; hl = literal/length/distance code lengths position
; ix = header code alphabet root
; iy = reader
HuffmanCodes_FillZero_11:
	call Reader_ReadBitsInline_7_IY
	add a,11
	ld b,a
	xor a
	jp HuffmanCodes_FillAndNext

;
HuffmanCodes_headerCodeOrder:
	db 16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15

HuffmanCodes_headerCodeSymbols:
	dw HuffmanCodes_WriteLength.0, HuffmanCodes_WriteLength.1, HuffmanCodes_WriteLength.2, HuffmanCodes_WriteLength.3
	dw HuffmanCodes_WriteLength.4, HuffmanCodes_WriteLength.5, HuffmanCodes_WriteLength.6, HuffmanCodes_WriteLength.7
	dw HuffmanCodes_WriteLength.8, HuffmanCodes_WriteLength.9, HuffmanCodes_WriteLength.10, HuffmanCodes_WriteLength.11
	dw HuffmanCodes_WriteLength.12, HuffmanCodes_WriteLength.13, HuffmanCodes_WriteLength.14, HuffmanCodes_WriteLength.15
	dw HuffmanCodes_Copy, HuffmanCodes_FillZero_3, HuffmanCodes_FillZero_11, System_ThrowException

HuffmanCodes_fixedLiteralLengthCodeLengths:
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8  ; 0-143: 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9  ; 144-255: 9
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 7, 7, 7, 7, 7, 7, 7, 7  ; 256-279: 7
	db 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8  ; 280-287: 8

HuffmanCodes_fixedLiteralLengthCodeLengthsCount: equ $ - HuffmanCodes_fixedLiteralLengthCodeLengths

HuffmanCodes_fixedDistanceCodeLengths:
	db 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5
	db 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5

HuffmanCodes_fixedDistanceCodeLengthsCount: equ $ - HuffmanCodes_fixedDistanceCodeLengths
