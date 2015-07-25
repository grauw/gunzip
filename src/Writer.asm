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
	count:
		dd 0
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
	push bc
	push de
	call Writer_IncreaseCount
	call Writer_FlushBuffer
	pop de
	pop bc
	ld h,(ix + Writer.bufferStart + 1)
	ret
	ENDP

; ix = this
; Modifies: af, bc, de, hl
Writer_FlushBuffer:
	jp ix

; ix = this
; Modifies: hl, bc
Writer_IncreaseCount:
	ld l,(ix + Writer.count)
	ld h,(ix + Writer.count + 1)
	ld c,(ix + Writer.bufferSize)
	ld b,(ix + Writer.bufferSize + 1)
	add hl,bc
	ld (ix + Writer.count),l
	ld (ix + Writer.count + 1),h
	ret nc
	inc (ix + Writer.count + 2)
	ret nz
	inc (ix + Writer.count + 3)
	ret

; ix = this
; dehl <- count bytes written
Writer_GetCount:
	ld l,(ix + Writer.bufferPosition)
	ld h,(ix + Writer.bufferPosition + 1)
	ld c,(ix + Writer.bufferStart)
	ld b,(ix + Writer.bufferStart + 1)
	and a
	sbc hl,bc
	call c,System_ThrowException
	ld c,(ix + Writer.count)
	ld b,(ix + Writer.count + 1)
	ld e,(ix + Writer.count + 2)
	ld d,(ix + Writer.count + 3)
	add hl,bc
	ret nc
	inc de
	ret
