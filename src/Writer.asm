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
	crc32:
		dd 0FFFFFFFFH
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
	call Writer_UpdateCRC32
	call Writer_FlushBuffer
	pop de
	pop bc
	ld h,(ix + Writer.bufferStart + 1)
	ret
	ENDP

; bc = byte count
; de = distance
; ix = this
Writer_Copy:
	ld l,(ix + Writer.bufferPosition)
	ld h,(ix + Writer.bufferPosition + 1)
	and a
	push hl
	sbc hl,de
	call c,System_ThrowException  ; TODO
	ld a,h
	cp (ix + Writer.bufferStart + 1)
	call c,System_ThrowException  ; TODO
	pop de
	push de
	ex de,hl
	add hl,bc
	call c,System_ThrowException  ; TODO
	ld a,h
	cp (ix + Writer.bufferEnd + 1)
	call nc,System_ThrowException  ; TODO
	ex de,hl
	pop de
	ldir
	ld (ix + Writer.bufferPosition),e
	ld (ix + Writer.bufferPosition + 1),d
	ret

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

; a = value
; ix = this
; Modifies: af, bc, de, hl
Writer_UpdateCRC32:
	exx
	push bc
	push hl
	ld l,(ix + Writer.bufferStart)
	ld h,(ix + Writer.bufferStart + 1)
	ld c,(ix + Writer.bufferSize)
	ld b,(ix + Writer.bufferSize + 1)
	exx
	ld l,(ix + Writer.crc32)
	ld h,(ix + Writer.crc32 + 1)
	ld e,(ix + Writer.crc32 + 2)
	ld d,(ix + Writer.crc32 + 3)
	call Writer_CalculateCRC32
	ld (ix + Writer.crc32),l
	ld (ix + Writer.crc32 + 1),h
	ld (ix + Writer.crc32 + 2),e
	ld (ix + Writer.crc32 + 3),d
	exx
	pop hl
	pop bc
	exx
	ret

; ix = this
; dehl <- crc32
; Modifies: af, bc, de, hl
Writer_GetCRC32:
	exx
	push bc
	push hl
	ld l,(ix + Writer.bufferPosition)
	ld h,(ix + Writer.bufferPosition + 1)
	ld c,(ix + Writer.bufferStart)
	ld b,(ix + Writer.bufferStart + 1)
	and a
	sbc hl,bc
	call c,System_ThrowException
	ld a,l
	ld l,c
	ld c,a
	ld a,h
	ld h,b
	ld b,a
	exx
	ld l,(ix + Writer.crc32)
	ld h,(ix + Writer.crc32 + 1)
	ld e,(ix + Writer.crc32 + 2)
	ld d,(ix + Writer.crc32 + 3)
	call nz,Writer_CalculateCRC32
	exx
	pop hl
	pop bc
	exx
	ret

; bc' = byte count
; hl' = read address
; dehl = current crc
; ix = this
; dehl <- updated crc
; Modifies: af, bc, de, hl, bc', hl'
Writer_CalculateCRC32: PROC
	exx
	ld a,c  ; convert 16-bit counter bc to two 8-bit counters in b and c
	dec bc
	inc b
	ld c,b
	ld b,a
Loop:
	ld a,(hl)
	inc hl
	exx
	xor l
	ld c,a
	ld b,CRC32Table >> 8
	ld a,(bc)
	xor h
	ld l,a
	inc b
	ld a,(bc)
	xor e
	ld h,a
	inc b
	ld a,(bc)
	xor d
	ld e,a
	inc b
	ld a,(bc)
	ld d,a
	exx
	djnz Loop
	dec c
	jp nz,Loop
	exx
	ret
	ENDP
