;
; Memory buffer writer
;
Writer: MACRO ?flusher
	FlushBuffer:
		jp ?flusher
	flusher: equ $ - 2
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

Writer_class: Class Writer, Writer_template, Heap_main
Writer_template: Writer System_ThrowException

; hl = buffer start
; bc = buffer size
; ix = this
; ix <- this
; de <- this
Writer_Construct:
	ld a,l  ; check if buffer is 256-byte aligned
	or c
	call nz,System_ThrowException
	ld (ix + Writer.bufferStart),l
	ld (ix + Writer.bufferStart + 1),h
	ld (ix + Writer.bufferSize),c
	ld (ix + Writer.bufferSize + 1),b
	ld (ix + Writer.bufferPosition),l
	ld (ix + Writer.bufferPosition + 1),h
	add hl,bc
	ld (ix + Writer.bufferEnd),l
	ld (ix + Writer.bufferEnd + 1),h
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
Writer_Destruct:
	ret

; a = value
; ix = this
; Modifies: hl
Writer_Write: PROC
	ld l,(ix + Writer.bufferPosition)
	ld h,(ix + Writer.bufferPosition + 1)
	ld (hl),a
	inc l
	ld (ix + Writer.bufferPosition),l
	ret nz
	inc h
	push af
	ld a,(ix + Writer.bufferEnd + 1)
	cp h
	call z,NextBlock
	pop af
	ld (ix + Writer.bufferPosition + 1),h
	ret
NextBlock:
	call Writer_FlushBuffer
	ld h,(ix + Writer.bufferStart + 1)
	ret
	ENDP

; ix = this
Writer_FlushBuffer:
	jp ix
