;
; Memory buffer reader
;
Reader: MACRO
	; ix = this
	Read:
		ld a,(0)
	bufferPosition: equ $ - 2
		inc (ix + Reader.bufferPosition)
		ret nz
		jp Reader_Read.Continue

	bufferStart:
		dw 0
	bufferSize:
		dw 0
	bufferEnd:
		dw 0
	filler:
		dw System_ThrowException
	byte:
		db 0
	bitCounter:
		db 1
	_size:
	ENDM

Reader_class: Class Reader, Reader_template, Heap_main
Reader_template: Reader

; hl = buffer start
; bc = buffer size
; ix = this
; ix <- this
; de <- this
Reader_Construct:
	ld a,l  ; check if buffer is 256-byte aligned
	or c
	call nz,System_ThrowException
	ld (ix + Reader.bufferStart),l
	ld (ix + Reader.bufferStart + 1),h
	ld (ix + Reader.bufferSize),c
	ld (ix + Reader.bufferSize + 1),b
	ld (ix + Reader.bufferPosition),l
	ld (ix + Reader.bufferPosition + 1),h
	add hl,bc
	ld (ix + Reader.bufferEnd),l
	ld (ix + Reader.bufferEnd + 1),h
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
Reader_Destruct:
	ret

; ix = this
; a <- value
; Modifies: none
Reader_Read: PROC
	jp ix
Continue:
	push af
	ld a,(ix + Reader.bufferPosition + 1)
	inc a
	cp (ix + Reader.bufferEnd + 1)
	call z,NextBlock
	ld (ix + Reader.bufferPosition + 1),a
	pop af
	ret
NextBlock:
	push bc
	push de
	push hl
	call Reader_FillBuffer
	pop hl
	pop de
	pop bc
	ld a,(ix + Reader.bufferStart + 1)
	ret
	ENDP

; ix = this
; Modifies: af, bc, de, hl
Reader_FillBuffer:
	ld l,(ix + Reader.filler)
	ld h,(ix + Reader.filler + 1)
	jp hl

; bc = nr of bytes to skip
; ix = this
; Modifies: bc, a
Reader_Skip:
	call Reader_Read
	dec bc
	ld a,b
	or c
	jr nz,Reader_Skip
	ret

; ix = this
; f <- c: bit
; Modifies: none
Reader_ReadBit:
	rr (ix + Reader.byte)
	dec (ix + Reader.bitCounter)
	ret nz
	push bc
	ld c,a
	call Reader_Read
	rra
	ld (ix + Reader.byte),a
	ld (ix + Reader.bitCounter),8
	ld a,c
	pop bc
	ret

; b <- current byte (shifts)
; c <- bits left + 1
Reader_PrepareReadBitInline:
	ld b,(ix + Reader.byte)
	ld c,(ix + Reader.bitCounter)
	ret

; b <- current byte (shifts)
; c <- bits left + 1
Reader_FinishReadBitInline:
	ld (ix + Reader.byte),b
	ld (ix + Reader.bitCounter),c
	ret

; b = current byte (shifts)
; c = bits left + 1
; b <- current byte (shifts)
; c <- bits left + 1
; f <- c: bit
; Modifies: none
Reader_ReadBitInline: MACRO
	dec c
	call z,Reader_ReadBitInline_NextByte
	rr b
	ENDM

; b <- current byte (shifts)
; c <- bits left
; f <- c: bit
; Modifies: none
Reader_ReadBitInline_NextByte:
	ld c,a
	call Reader_Read
	ld b,a
	ld a,c
	ld c,8
	ret

; bc = inline bit reader state
; a <- value
; bc <- inline bit reader state
; Modifies: none
Reader_ReadBitsInline_1:
	xor a
	Reader_ReadBitInline
	rla
	ret

Reader_ReadBitsInline_2:
	xor a
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	rra
	rra
	rra
	rra
	rra
	rra
	ret

Reader_ReadBitsInline_3:
	xor a
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	rra
	rra
	rra
	rra
	rra
	ret

Reader_ReadBitsInline_4:
	xor a
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	rra
	rra
	rra
	rra
	ret

Reader_ReadBitsInline_5:
	xor a
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	rra
	rra
	rra
	ret

Reader_ReadBitsInline_6:
	xor a
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	rra
	rra
	ret

Reader_ReadBitsInline_7:
	xor a
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	rra
	ret

Reader_ReadBitsInline_8:
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	Reader_ReadBitInline
	rra
	ret

; b = nr of bits to read (1-8)
; ix = this
; a <- value
; Modifies: af, bc
Reader_ReadBits: PROC
	ld c,1
	xor a
Loop:
	call Reader_ReadBit
	jr nc,Zero
	add a,c
Zero:
	rlc c
	djnz Loop
	ret
	ENDP

; b = nr of bits to read (1-8)
; iy = this
; a <- value
; Modifies: af, bc
Reader_ReadBits_IY:
	push iy
	ex (sp),ix
	call Reader_ReadBits
	pop ix
	ret

; ix = this
Reader_Align:
	ld (ix + Reader.bitCounter),1
	ret
