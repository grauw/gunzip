;
; The dynamic alphabets
;
HuffmanCodes_MAX_HEADERCODELENGTHS: equ 19
HuffmanCodes_MAX_LITERALLENGTHCODELENGTHS: equ 286
HuffmanCodes_MAX_DISTANCECODELENGTHS: equ 30
HuffmanCodes_FIXED_LITERALLENGTHCODELENGTHS: equ HuffmanCodes_MAX_LITERALLENGTHCODELENGTHS + 2
HuffmanCodes_FIXED_DISTANCECODELENGTHS: equ HuffmanCodes_MAX_DISTANCECODELENGTHS + 2

HuffmanCodes: MACRO
	alphabet:
		Alphabet
	literalLengthHandlers:
		dw 0
	distanceHandlers:
		dw 0
	decoders:
		dw 0
	hlit:
		db 0  ; we only store the LSB, MSB is always 1
	hdist:
		db 0
	hclen:
		db 0
	_size:
	ENDM

; bc = decoders buffer
; hl = literal/length symbol handlers table
; de = distance symbol handlers table
; ix = this
HuffmanCodes_Construct:
	ld (ix + HuffmanCodes.literalLengthHandlers),l
	ld (ix + HuffmanCodes.literalLengthHandlers + 1),h
	ld (ix + HuffmanCodes.distanceHandlers),e
	ld (ix + HuffmanCodes.distanceHandlers + 1),d
	ld (ix + HuffmanCodes.decoders),c
	ld (ix + HuffmanCodes.decoders + 1),b
	ret

; ix = this
; iy = reader
; ix <- this
HuffmanCodes_ConstructDynamic:
	call HuffmanCodes_ReadLengths
	call HuffmanCodes_ReadHeaderCodeLengths
	call HuffmanCodes_ConstructHeaderCodeAlphabet
	call HuffmanCodes_ReadLiteralLengthDistanceCodeLengths
	call HuffmanCodes_ConstructLiteralLengthAlphabet
	call HuffmanCodes_ConstructDistanceAlphabet
	ret

; ix = this
; ix <- this
HuffmanCodes_ConstructFixed:
	ld bc,HuffmanCodes_fixedLiteralLengthCodeLengthsCount
	ld de,HuffmanCodes_fixedLiteralLengthCodeLengths
	ld l,(ix + HuffmanCodes.literalLengthHandlers)
	ld h,(ix + HuffmanCodes.literalLengthHandlers + 1)
	call Alphabet_Construct
	ld e,(ix + HuffmanCodes.decoders)
	ld d,(ix + HuffmanCodes.decoders + 1)
	call Decoders_GetLiteralLengthDecoder
	call Alphabet_BuildDecoder
	ld bc,HuffmanCodes_fixedDistanceCodeLengthsCount
	ld de,HuffmanCodes_fixedDistanceCodeLengths
	ld l,(ix + HuffmanCodes.distanceHandlers)
	ld h,(ix + HuffmanCodes.distanceHandlers + 1)
	call Alphabet_Construct
	ld e,(ix + HuffmanCodes.decoders)
	ld d,(ix + HuffmanCodes.decoders + 1)
	call Decoders_GetDistanceDecoder
	jp Alphabet_BuildDecoder

; ix = this
HuffmanCodes_ConstructHeaderCodeAlphabet:
	ld e,(ix + HuffmanCodes.decoders)
	ld d,(ix + HuffmanCodes.decoders + 1)
	push de
	ld bc,HuffmanCodes_MAX_HEADERCODELENGTHS
	ld hl,HuffmanCodes_headerCodeSymbols
	call Alphabet_Construct
	pop de
	call Decoders_GetDistanceDecoder
	jp Alphabet_BuildDecoder

; ix = this
HuffmanCodes_ConstructLiteralLengthAlphabet:
	ld e,(ix + HuffmanCodes.decoders)
	ld d,(ix + HuffmanCodes.decoders + 1)
	push de
	ld c,(ix + HuffmanCodes.hlit)
	ld b,1
	ld l,(ix + HuffmanCodes.literalLengthHandlers)
	ld h,(ix + HuffmanCodes.literalLengthHandlers + 1)
	call Alphabet_Construct
	pop de
	call Decoders_GetLiteralLengthDecoder
	jp Alphabet_BuildDecoder

; ix = this
HuffmanCodes_ConstructDistanceAlphabet:
	ld e,(ix + HuffmanCodes.decoders)
	ld d,(ix + HuffmanCodes.decoders + 1)
	push de
	ld hl,Decoders.distance
	add hl,de
	ex de,hl
	ld c,(ix + HuffmanCodes.hdist)
	ld b,0
	ld l,(ix + HuffmanCodes.distanceHandlers)
	ld h,(ix + HuffmanCodes.distanceHandlers + 1)
	call Alphabet_Construct
	pop de
	call Decoders_GetDistanceDecoder
	jp Alphabet_BuildDecoder

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
	ld e,(ix + HuffmanCodes.decoders)
	ld d,(ix + HuffmanCodes.decoders + 1)
	push de
	ld l,e
	ld h,d
	inc de
	ld (hl),0
	ld bc,HuffmanCodes_MAX_HEADERCODELENGTHS - 1
	ldir
	pop de
	ld b,(ix + HuffmanCodes.hclen)
	ld hl,HuffmanCodes_headerCodeOrder
Loop:
	push bc
	ld b,3
	call Reader_ReadBits_IY
	ld c,(hl)  ; b = 0 after ReadBits
	inc hl
	ex de,hl
	add hl,bc
	ld (hl),a
	sbc hl,bc
	ex de,hl
	pop bc
	djnz Loop
	ret
	ENDP

; ix = this
; iy = reader
HuffmanCodes_ReadLiteralLengthDistanceCodeLengths:
	ld e,(ix + HuffmanCodes.decoders)
	ld d,(ix + HuffmanCodes.decoders + 1)
	ld hl,Decoders.distance
	add hl,de
	ex de,hl
	ld a,(ix + HuffmanCodes.hlit)
	add a,(ix + HuffmanCodes.hdist)
	push de
	push hl
	push ix
	ld ixl,e
	ld ixh,d
	ld e,a
	ld d,2  ; +1 for nested 8-bit loop
	call Reader_PrepareReadBitInline_IY
	call HuffmanCodes_DecodeLiteralLengthDistanceCodeLengths
	call Reader_FinishReadBitInline_IY
	pop ix
	pop hl
	pop de
	ld c,(ix + HuffmanCodes.hlit)
	ld b,1
	add hl,bc
	ld c,(ix + HuffmanCodes.hdist)
	ld b,0
	ldir
	ret

; c = inline bit reader state
; de = loop counter for nested 8-bit loop
; hl = literal/length/distance code lengths position
; ix = header code decoder
; iy = reader
HuffmanCodes_DecodeLiteralLengthDistanceCodeLengths:
	jp ix

; c = inline bit reader state
; de = loop counter for nested 8-bit loop
; hl = literal/length/distance code lengths position
; ix = header code decoder
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
; ix = header code decoder
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
; ix = header code decoder
; iy = reader
HuffmanCodes_WriteLength: REPT 16, ?value
	ld (hl),?value
	jp HuffmanCodes_WriteAndNext
	ENDM

; Header code alphabet symbols 16
; c = inline bit reader state
; de = loop counter for nested 8-bit loop
; hl = literal/length/distance code lengths position
; ix = header code decoder
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
; ix = header code decoder
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
; ix = header code decoder
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

	IF HuffmanCodes_fixedLiteralLengthCodeLengthsCount != HuffmanCodes_FIXED_LITERALLENGTHCODELENGTHS
	ERROR "Fixed literal length code lengths count mismatch."
	ENDIF

HuffmanCodes_fixedDistanceCodeLengths:
	db 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5
	db 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5

HuffmanCodes_fixedDistanceCodeLengthsCount: equ $ - HuffmanCodes_fixedDistanceCodeLengths

	IF HuffmanCodes_fixedDistanceCodeLengthsCount != HuffmanCodes_FIXED_DISTANCECODELENGTHS
	ERROR "Fixed distance code lengths count mismatch."
	ENDIF
