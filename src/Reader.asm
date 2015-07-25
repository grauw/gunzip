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
	fileHandle:
		db 0FFH
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
	call Reader_FillBuffer
	ld h,(ix + Reader.bufferStart + 1)
	ret
	ENDP

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
Reader_FillBuffer:
	jp ix
