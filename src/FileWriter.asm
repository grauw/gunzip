;
; Buffered sequential-access file writer
;
FileWriter: MACRO
	super: Writer
	fileHandle:
		db 0FFH
	_size:
	ENDM

FileWriter_class: Class FileWriter, FileWriter_template, Heap_main
FileWriter_template: FileWriter

; de = file path
; hl = buffer start
; bc = buffer size
; ix = this
; ix <- this
; de <- this
FileWriter_Construct:
	push de
	call Writer_Construct
	pop de
	ld a,00000010B  ; write only
	ld b,0
	ld c,_CREATE
	call BDOS
	call Application_CheckDOSError
	ld (ix + FileWriter.fileHandle),b
	ld (ix + FileWriter.super.flusher),FileWriter_WriteToFile & 0FFH
	ld (ix + FileWriter.super.flusher + 1),FileWriter_WriteToFile >> 8
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
FileWriter_Destruct:
	call FileWriter_WriteToFile
	ld b,(ix + FileWriter.fileHandle)
	ld c,_CLOSE
	call BDOS
	call Application_CheckDOSError
	call Writer_Destruct
	ret

; ix = this
; Modifies: af, bc, de, hl
FileWriter_WriteToFile:
	ld c,_CONST  ; allow ctrl-c
	call BDOS
	ld b,(ix + FileWriter.fileHandle)
	ld e,(ix + FileWriter.super.bufferStart)
	ld d,(ix + FileWriter.super.bufferStart + 1)
	ld l,(ix + FileWriter.super.bufferPosition)
	ld h,(ix + FileWriter.super.bufferPosition + 1)
	and a
	sbc hl,de
	ld c,_WRITE
	call BDOS
	call Application_CheckDOSError
	ret
