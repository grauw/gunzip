;
; Memory buffer reader
;
Reader: MACRO ?filler
	FillBuffer:
		jp ?filler
	filler: equ $ - 2
	bufferStart:
		dw 0
	bufferSize:
		dw 0
	bufferEnd:
		dw 0
	bufferPosition:
		dw 0
	byte:
		db 0
	bitCounter:
		db 1
	_size:
	ENDM

Reader_class: Class Reader, Reader_template, Heap_main
Reader_template: Reader System_ThrowException

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
; Modifies: hl
Reader_Read: PROC
	ld l,(ix + Reader.bufferPosition)
	ld h,(ix + Reader.bufferPosition + 1)
	ld a,(hl)
	inc l
	ld (ix + Reader.bufferPosition),l
	ret nz
	inc h
	ld l,a
	ld a,(ix + Reader.bufferEnd + 1)
	cp h
	ld a,l
	call z,NextBlock
	ld (ix + Reader.bufferPosition + 1),h
	ret
NextBlock:
	push af
	push bc
	push de
	call Reader_FillBuffer
	pop de
	pop bc
	pop af
	ld h,(ix + Reader.bufferStart + 1)
	ret
	ENDP

; ix = this
; Modifies: af, bc, de, hl
Reader_FillBuffer:
	jp ix

; bc = nr of bytes to skip
; ix = this
; Modifies: hl, a
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
	push hl
	ld c,a
	call Reader_Read
	rra
	ld (ix + Reader.byte),a
	ld (ix + Reader.bitCounter),8
	ld a,c
	pop hl
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
Reader_ReadBitInline: MACRO
	dec c
	call z,Reader_ReadBitInline_NextByte
	rr b
	ENDM

; b <- current byte (shifts)
; c <- bits left
; f <- c: bit
Reader_ReadBitInline_NextByte:
	push hl
	ld c,a
	call Reader_Read
	ld b,a
	ld a,c
	ld c,8
	pop hl
	ret

; a = nr of bits to read (1-8)
; bc = inline bit reader state
; a <- value
; bc <- inline bit reader state
; Modifies: af
Reader_ReadBitsInline: PROC
	push de
	ld d,a
	ld e,1
	xor a
Loop:
	Reader_ReadBitInline
	jr nc,Zero
	add a,e
Zero:
	rlc e
	dec d
	jp nz,Loop
	pop de
	ret
	ENDP

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
