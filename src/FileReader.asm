;
; Buffered sequential-access file reader
;
FileReader: MACRO
	super: Reader FileReader_ReadFromFile
	fileHandle:
		db 0FFH
	_size:
	ENDM

FileReader_class: Class FileReader, FileReader_template, Heap_main
FileReader_template: FileReader

; de = file path
; hl = buffer start
; bc = buffer size
; ix = this
; ix <- this
; de <- this
FileReader_Construct:
	push de
	call Reader_Construct
	pop de
	ld a,00000001B  ; read only
	ld c,_OPEN
	call BDOS
	call Application_CheckDOSError
	ld (ix + FileReader.fileHandle),b
	ld l,(ix + FileReader.super.bufferStart)
	ld h,(ix + FileReader.super.bufferStart + 1)
	ld (ix + FileReader.super.bufferPosition),l
	ld (ix + FileReader.super.bufferPosition + 1),h
	call FileReader_ReadFromFile
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
FileReader_Destruct:
	ld b,(ix + FileReader.fileHandle)
	ld c,_CLOSE
	call BDOS
	call Application_CheckDOSError
	call Reader_Destruct
	ret

; ix = this
; Modifies: af, bc, de, hl
FileReader_ReadFromFile: PROC
	ld b,(ix + FileReader.fileHandle)
	ld e,(ix + FileReader.super.bufferStart)
	ld d,(ix + FileReader.super.bufferStart + 1)
	ld l,(ix + FileReader.super.bufferEnd)
	ld h,(ix + FileReader.super.bufferEnd + 1)
	and a
	sbc hl,de
	ld c,_READ
	call BDOS
	cp .EOF
	jp z,EndOfFile
	call Application_CheckDOSError
	ret
EndOfFile:
	; TODO
	ret
	ENDP
