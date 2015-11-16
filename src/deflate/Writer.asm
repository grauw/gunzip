;
; Memory buffer writer
;
Writer: MACRO
	; a = value
	; hl = return address
	; iy = this
	Write_IY:
		ld (0),a
	bufferPosition: equ $ - 2
		inc (iy + Writer.bufferPosition)
		jr z,Write_IY_Continue  ; unlikely
		jp hl
	Write_IY_Continue:
		push hl
		jp Writer_Write_IY.Continue

	bufferStart:
		dw 0
	bufferSize:
		dw 0
	bufferEnd:
		dw 0
	bufferEndCopyMargin:
		db 0
	flusher:
		dw Writer_DefaultFlusher
	count:
		dd 0
	_size:
	ENDM

Writer_class: Class Writer, Writer_template, Heap_main
Writer_template: Writer

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
	dec h
	dec h
	dec h
	ld (ix + Writer.bufferEndCopyMargin),h
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
Writer_Destruct:
	ret

; a = value
; iy = this
; Modifies: hl
Writer_WriteInline_JumpHL_IY: MACRO
	jp iy
	ENDM

; a = value
; iy = this
; Modifies: hl
Writer_Write_IY: PROC
	pop hl
	jp iy
Continue:
	push af
	ld a,(iy + Writer.bufferPosition + 1)
	inc a
	ld (iy + Writer.bufferPosition + 1),a
	cp (iy + Writer.bufferEnd + 1)
	call z,Writer_FinishBlock_IY
	pop af
	ret
	ENDP

; bc = byte count (range 3-258)
; hl = -distance
; iy = this
; Modifies: af, bc, de, hl
Writer_Copy_IY: PROC
	ld e,(iy + Writer.bufferPosition)
	ld d,(iy + Writer.bufferPosition + 1)
	add hl,de
	ld a,h
	jr nc,Wrap
	cp (iy + Writer.bufferStart + 1)
	jr c,Wrap
	ld a,(iy + Writer.bufferEndCopyMargin)
WrapContinue:
	cp d  ; does the destination have a 512 byte margin without wrapping?
	jr c,Writer_Copy_Slow_IY
	ldi
	ldi
	ldir
	ld (iy + Writer.bufferPosition),e
	ld (iy + Writer.bufferPosition + 1),d
	ret
Wrap:
	add a,(iy + Writer.bufferSize + 1)
	ld h,a
	ld a,(iy + Writer.bufferEndCopyMargin)
	cp h  ; does the source have a 512 byte margin without wrapping?
	jp nc,WrapContinue
	jp Writer_Copy_Slow_IY
	ENDP

; bc = byte count
; hl = buffer source
; de = buffer destination
; iy = this
; Modifies: af, bc, de, hl
Writer_Copy_Slow_IY: PROC
	ld e,l
	ld d,h
	add hl,bc
	jr c,Split
	ld a,h
	cp (iy + Writer.bufferEnd + 1)
	jp c,Writer_WriteBlock_IY
; hl = end address
Split:
	push bc
	ld c,(iy + Writer.bufferEnd)
	ld b,(iy + Writer.bufferEnd + 1)
	and a
	sbc hl,bc  ; hl = bytes past end
	ex (sp),hl
	pop bc
	push bc
	sbc hl,bc  ; hl = bytes until end
	ld c,l
	ld b,h
	call Writer_WriteBlock_IY
	pop bc
	ld l,(iy + Writer.bufferStart)
	ld h,(iy + Writer.bufferStart + 1)
	ld a,b
	or c
	jp nz,Writer_Copy_Slow_IY
	ret
	ENDP

; bc = byte count
; de = source
; iy = this
; Modifies: af, bc, de, hl
Writer_WriteBlock_IY: PROC
	ld l,(iy + Writer.bufferPosition)
	ld h,(iy + Writer.bufferPosition + 1)
	add hl,bc
	jr c,Split
	ld a,h
	cp (iy + Writer.bufferEnd + 1)
	jr nc,Split
	and a
	sbc hl,bc
	ex de,hl
	ldir
	ld (iy + Writer.bufferPosition),e
	ld (iy + Writer.bufferPosition + 1),d
	ret
; hl = end address
Split:
	push bc
	ld c,(iy + Writer.bufferEnd)
	ld b,(iy + Writer.bufferEnd + 1)
	and a
	sbc hl,bc  ; hl = bytes past end
	ld c,l
	ld b,h
	ex (sp),hl
	sbc hl,bc  ; hl = bytes until end
	ld c,l
	ld b,h
	ex de,hl
	ld e,(iy + Writer.bufferPosition)
	ld d,(iy + Writer.bufferPosition + 1)
	ldir
	ld (iy + Writer.bufferPosition),e
	ld (iy + Writer.bufferPosition + 1),d
	call Writer_FinishBlock_IY
	ex de,hl
	ld l,(ix + Writer.bufferPosition)
	ld h,(ix + Writer.bufferPosition + 1)
	pop bc
	ld a,b
	or c
	jp nz,Writer_WriteBlock_IY
	ret
	ENDP

; ix = this
; hl <- buffer position
; Modifies: af
Writer_FinishBlock: PROC
	push bc
	push de
	push hl
	ld l,(ix + Writer.bufferPosition)
	ld h,(ix + Writer.bufferPosition + 1)
	ld e,(ix + Writer.bufferStart)
	ld d,(ix + Writer.bufferStart + 1)
	and a
	sbc hl,de
	call c,System_ThrowException
	jr z,Empty
	ld c,l
	ld b,h
	push bc
	push de
	call Writer_IncreaseCount
	pop de
	pop bc
	call Writer_FlushBuffer
Empty:
	pop hl
	pop de
	pop bc
	ld a,(ix + Writer.bufferStart)
	ld (ix + Writer.bufferPosition),a
	ld a,(ix + Writer.bufferStart + 1)
	ld (ix + Writer.bufferPosition + 1),a
	ret
	ENDP

; iy = this
; hl <- buffer position
; Modifies: af
Writer_FinishBlock_IY:
	push iy
	ex (sp),ix
	call Writer_FinishBlock
	pop ix
	ret

; The flusher is called with de = buffer start, bc = byte count
; ix = this
; Modifies: af, bc, de, hl
Writer_FlushBuffer:
	ld l,(ix + Writer.flusher)
	ld h,(ix + Writer.flusher + 1)
	jp hl

; ix = this
Writer_DefaultFlusher:
	ret

; bc = byte count
; ix = this
; Modifies: hl
Writer_IncreaseCount:
	ld l,(ix + Writer.count)
	ld h,(ix + Writer.count + 1)
	add hl,bc
	ld (ix + Writer.count),l
	ld (ix + Writer.count + 1),h
	ret nc
	inc (ix + Writer.count + 2)
	ret nz
	inc (ix + Writer.count + 3)
	ret

; ix = this
; bcde <- count bytes written
Writer_GetCount:
	ld e,(ix + Writer.count)
	ld d,(ix + Writer.count + 1)
	ld c,(ix + Writer.count + 2)
	ld b,(ix + Writer.count + 3)
	ret
