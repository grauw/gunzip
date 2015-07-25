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
	push af
	ld a,(ix + Reader.bufferEnd + 1)
	cp h
	call z,NextBlock
	pop af
	ld (ix + Reader.bufferPosition + 1),h
	ret
NextBlock:
	push bc
	push de
	call Reader_FillBuffer
	pop de
	pop bc
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
Reader_ReadBit:
	rr (ix + Reader.byte)
	dec (ix + Reader.bitCounter)
	ret nz
	call Reader_Read
	rra
	ld (ix + Reader.byte),a
	ld (ix + Reader.bitCounter),8
	ret

; b = nr of bits to read (1-8)
; ix = this
; a = value
Reader_ReadBits: PROC
	ld a,9
	sub b
	call c,System_ThrowException
	call z,System_ThrowException
	ld c,a
	xor a
Loop1:
	call Reader_ReadBit
	rra
	djnz Loop1
	dec c
	ret z
	ld b,c
Loop2:
	rrca
	djnz Loop2
	ret
	ENDP

; ix = this
Reader_Align:
	ld (ix + Reader.bitCounter),1
	ret
