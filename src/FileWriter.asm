;
; Buffered sequential-access file writer
;
FileWriter: MACRO
	bufferStart:
		dw 0
	bufferEnd:
		dw 0
	bufferPosition:
		dw 0
	fileHandle:
		db 0FFH
	_size:
	ENDM

FileWriter_class: Class FileWriter, FileWriter_template, Heap_main
FileWriter_template: FileWriter

; hl = buffer start
; bc = buffer size
; ix = this
; ix <- this
; de <- this
FileWriter_Construct:
	ld a,l  ; check if buffer is 256-byte aligned
	or c
	call nz,System_ThrowException
	ld (ix + FileWriter.bufferStart),l
	ld (ix + FileWriter.bufferStart + 1),h
	ld (ix + FileWriter.bufferPosition),l
	ld (ix + FileWriter.bufferPosition + 1),h
	add hl,bc
	ld (ix + FileWriter.bufferEnd),l
	ld (ix + FileWriter.bufferEnd + 1),h
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
FileWriter_Destruct:
	ld a,(ix + FileWriter.fileHandle)  ; check if file was closed
	cp 0FFH
	call nz,System_ThrowException
	ret

; de = file path
; ix = this
FileWriter_Open:
	ld a,(ix + FileWriter.fileHandle)  ; check if file was not already opened
	cp 0FFH
	call nz,System_ThrowException
	ld a,00000010B  ; write only
	ld b,0
	ld c,_CREATE
	call BDOS
	call Application_CheckDOSError
	ld (ix + FileWriter.fileHandle),b
	ld l,(ix + FileWriter.bufferStart)
	ld h,(ix + FileWriter.bufferStart + 1)
	ld (ix + FileWriter.bufferPosition),l
	ld (ix + FileWriter.bufferPosition + 1),h
	ret

; ix = this
FileWriter_Close:
	call FileWriter_WriteToFile
	ld b,(ix + FileWriter.fileHandle)
	ld c,_CLOSE
	call BDOS
	call Application_CheckDOSError
	ld (ix + FileWriter.fileHandle),0FFH
	ret

; a = value
; ix = this
; Modifies: hl
FileWriter_Write: PROC
	ld l,(ix + FileWriter.bufferPosition)
	ld h,(ix + FileWriter.bufferPosition + 1)
	ld (hl),a
	inc l
	ld (ix + FileWriter.bufferPosition),l
	ret nz
	inc h
	push af
	ld a,(ix + FileWriter.bufferEnd + 1)
	cp h
	call z,NextBlock
	pop af
	ld (ix + FileWriter.bufferPosition + 1),h
	ret
NextBlock:
	push bc
	push de
	call FileWriter_WriteToFile
	pop de
	pop bc
	ld h,(ix + FileWriter.bufferStart + 1)
	ret
	ENDP

; ix = this
FileWriter_WriteToFile:
	ld b,(ix + FileWriter.fileHandle)
	ld e,(ix + FileWriter.bufferStart)
	ld d,(ix + FileWriter.bufferStart + 1)
	ld l,(ix + FileWriter.bufferPosition)
	ld h,(ix + FileWriter.bufferPosition + 1)
	and a
	sbc hl,de
	ld c,_WRITE
	call BDOS
	call Application_CheckDOSError
	ret
