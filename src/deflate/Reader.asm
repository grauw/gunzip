;
; Memory buffer reader
;
Reader: MACRO
	; ix = this
	; a <- value
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
		dw Reader_DefaultFiller
	fillPending:
		db 0
	bits:
		db 0
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
	add hl,bc
	ld (ix + Reader.bufferEnd),l
	ld (ix + Reader.bufferEnd + 1),h
	dec hl  ; trap the next read
	ld (ix + Reader.bufferPosition),l
	ld (ix + Reader.bufferPosition + 1),h
	ld (ix + Reader.fillPending),-1
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
Reader_Destruct:
	ret

; iy = this
; a <- value
; Modifies: none
Reader_Read_IY:
	push iy
	ex (sp),ix
	call Reader_Read
	ex (sp),ix
	pop iy
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
	ld (ix + Reader.bufferPosition + 1),a
	cp (ix + Reader.bufferEnd + 1)
	jr z,FinishBlock
	pop af
	ret
FinishBlock:
	pop af
	bit 0,(ix + Reader.fillPending)
	jr nz,PendingFill
	ld (ix + Reader.fillPending),-1
	ld (ix + Reader.bufferPosition),0FFH
	dec (ix + Reader.bufferPosition + 1)
	ret
PendingFill:
	ld (ix + Reader.fillPending),0
	call Reader_FinishBlock
	jp ix
	ENDP

; ix = this
Reader_FinishBlock:
	push bc
	push de
	push hl
	call Reader_FillBuffer
	pop hl
	pop de
	pop bc
	ld a,(ix + Reader.bufferStart)
	ld (ix + Reader.bufferPosition),a
	ld a,(ix + Reader.bufferStart + 1)
	ld (ix + Reader.bufferPosition + 1),a
	ret

; The filler is called with de = buffer start, bc = byte count
; ix = this
; Modifies: af, bc, de, hl
Reader_FillBuffer:
	ld a,(ix + Reader.bufferPosition)
	cp (ix + Reader.bufferEnd)
	call nz,System_ThrowException
	ld a,(ix + Reader.bufferPosition + 1)
	cp (ix + Reader.bufferEnd + 1)
	call nz,System_ThrowException
	ld l,(ix + Reader.bufferPosition)
	ld h,(ix + Reader.bufferPosition + 1)
	ld e,(ix + Reader.bufferStart)
	ld d,(ix + Reader.bufferStart + 1)
	and a
	sbc hl,de
	ret z
	call c,System_ThrowException
	ld c,l
	ld b,h
	ld l,(ix + Reader.filler)
	ld h,(ix + Reader.filler + 1)
	jp hl

; ix = this
Reader_DefaultFiller:
	ret

; bc = nr of bytes to skip
; iy = this
; Modifies: bc, a
Reader_Skip_IY:
	call Reader_Read_IY
	dec bc
	ld a,b
	or c
	jr nz,Reader_Skip_IY
	ret

; iy = this
; f <- c: bit
; Modifies: none
Reader_ReadBit_IY:
	srl (iy + Reader.bits)
	ret nz  ; return if sentinel bit is still present
	push bc
	ld c,a
	call Reader_Read_IY
	scf  ; set sentinel bit
	rra
	ld (iy + Reader.bits),a
	ld a,c
	pop bc
	ret

; c <- inline bit reader state
Reader_PrepareReadBitInline:
	ld c,(ix + Reader.bits)
	ret

; c = inline bit reader state
Reader_FinishReadBitInline:
	ld (ix + Reader.bits),c
	ret

; c = inline bit reader state
; c <- inline bit reader state
; f <- c: bit
; Modifies: a
Reader_ReadBitInline: MACRO
	srl c
	call z,Reader_ReadBitInline_NextByte  ; if sentinel bit is shifted out
	ENDM

; c <- inline bit reader state
; f <- c: bit
; Modifies: a
Reader_ReadBitInline_NextByte:
	call Reader_Read
	scf  ; set sentinel bit
	rra
	ld c,a
	ret

; c = inline bit reader state
; c <- inline bit reader state
; f <- c: bit
; Modifies: b
Reader_ReadBitInline_B: MACRO
	srl c
	call z,Reader_ReadBitInline_B_NextByte  ; if sentinel bit is shifted out
	ENDM

; c <- inline bit reader state
; f <- c: bit
; Modifies: b
Reader_ReadBitInline_B_NextByte:
	ld b,a
	call Reader_Read
	scf  ; set sentinel bit
	rra
	ld c,a
	ld a,b
	ret

; c = inline bit reader state
; a <- value
; c <- inline bit reader state
; Modifies: b
Reader_ReadBitsInline_1:
	xor a
	Reader_ReadBitInline_B
	rla
	ret

Reader_ReadBitsInline_2:
	xor a
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rla
	rla
	ret

Reader_ReadBitsInline_3:
	xor a
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rla
	rla
	rla
	ret

Reader_ReadBitsInline_4:
	xor a
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rla
	rla
	rla
	rla
	ret

Reader_ReadBitsInline_5:
	xor a
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	rra
	rra
	rra
	ret

Reader_ReadBitsInline_6:
	xor a
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	rra
	rra
	ret

Reader_ReadBitsInline_7:
	xor a
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	rra
	ret

Reader_ReadBitsInline_8:
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	Reader_ReadBitInline_B
	rra
	ret

; b = nr of bits to read (1-8)
; iy = this
; a <- value
; Modifies: af, bc
Reader_ReadBits_IY: PROC
	ld c,1
	xor a
Loop:
	call Reader_ReadBit_IY
	jr nc,Zero
	add a,c
Zero:
	rlc c
	djnz Loop
	ret
	ENDP

; iy = this
Reader_Align_IY:
	ld (iy + Reader.bits),0
	ret
