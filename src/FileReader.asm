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

; hl = buffer start
; bc = buffer size
; ix = this
; ix <- this
; de <- this
FileReader_Construct:
	call Reader_Construct
	ret

; ix = this
; ix <- this
FileReader_Destruct:
	ld a,(ix + FileReader.fileHandle)  ; check if file was closed
	cp 0FFH
	call nz,System_ThrowException
	call Reader_Destruct
	ret

; de = file path
; ix = this
FileReader_Open:
	ld a,(ix + FileReader.fileHandle)  ; check if file was not already opened
	cp 0FFH
	call nz,System_ThrowException
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
	ret

; ix = this
FileReader_Close:
	ld b,(ix + FileReader.fileHandle)
	ld c,_CLOSE
	call BDOS
	call Application_CheckDOSError
	ld (ix + FileReader.fileHandle),0FFH
	ret

; ix = this
; Modifies: hl
FileReader_ReadFromFile: PROC
	push bc
	push de
	ld b,(ix + FileReader.fileHandle)
	ld e,(ix + FileReader.super.bufferStart)
	ld d,(ix + FileReader.super.bufferStart + 1)
	ld l,(ix + FileReader.super.bufferEnd)
	ld h,(ix + FileReader.super.bufferEnd + 1)
	and a
	sbc hl,de
	ld c,_READ
	call BDOS
	pop de
	pop bc
	cp .EOF
	jp z,EndOfFile
	call Application_CheckDOSError
	ret
EndOfFile:
	; TODO
	ret
	ENDP
