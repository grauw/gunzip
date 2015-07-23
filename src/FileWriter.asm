;
; Buffered sequential-access file writer
;
FileWriter: MACRO
	super: Writer FileWriter_WriteToFile
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
	call Writer_Construct
	ret

; ix = this
; ix <- this
FileWriter_Destruct:
	ld a,(ix + FileWriter.fileHandle)  ; check if file was closed
	cp 0FFH
	call nz,System_ThrowException
	call Writer_Destruct
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
	ld l,(ix + FileWriter.super.bufferStart)
	ld h,(ix + FileWriter.super.bufferStart + 1)
	ld (ix + FileWriter.super.bufferPosition),l
	ld (ix + FileWriter.super.bufferPosition + 1),h
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

; ix = this
; Modifies: hl
FileWriter_WriteToFile:
	push bc
	push de
	ld b,(ix + FileWriter.fileHandle)
	ld e,(ix + FileWriter.super.bufferStart)
	ld d,(ix + FileWriter.super.bufferStart + 1)
	ld l,(ix + FileWriter.super.bufferPosition)
	ld h,(ix + FileWriter.super.bufferPosition + 1)
	and a
	sbc hl,de
	ld c,_WRITE
	call BDOS
	pop de
	pop bc
	call Application_CheckDOSError
	ret
