;
; Buffered sequential-access file reader
;
FileReader: MACRO
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

FileReader_class: Class FileReader, FileReader_template, FileReader_Constructor, FileReader_Destructor, Heap_main
FileReader_template: FileReader

; hl = buffer start
; bc = buffer size
; ix = this
; ix <- this
FileReader_Constructor:
	ld a,l  ; check if buffer is 256-byte aligned
	or c
	call nz,System_ThrowException
	ld (ix + FileReader.bufferStart),l
	ld (ix + FileReader.bufferStart + 1),h
	ld (ix + FileReader.bufferPosition),l
	ld (ix + FileReader.bufferPosition + 1),h
	add hl,bc
	ld (ix + FileReader.bufferEnd),l
	ld (ix + FileReader.bufferEnd + 1),h
	ret

; ix = this
; ix <- this
FileReader_Destructor:
	ld a,(ix + FileReader.fileHandle)  ; check if file was closed
	cp 0FFH
	call nz,System_ThrowException
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
	ld l,(ix + FileReader.bufferStart)
	ld h,(ix + FileReader.bufferStart + 1)
	ld (ix + FileReader.bufferPosition),l
	ld (ix + FileReader.bufferPosition + 1),h
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
; a <- value
; Modifies: hl
FileReader_Read: PROC
	ld l,(ix + FileReader.bufferPosition)
	ld h,(ix + FileReader.bufferPosition + 1)
	ld a,(hl)
	inc l
	ld (ix + FileReader.bufferPosition),l
	ret nz
	inc h
	push af
	ld a,(ix + FileReader.bufferEnd + 1)
	cp h
	call z,NextBlock
	pop af
	ld (ix + FileReader.bufferPosition + 1),h
	ret
NextBlock:
	push bc
	push de
	call FileReader_ReadFromFile
	pop de
	pop bc
	ld h,(ix + FileReader.bufferStart + 1)
	ret
	ENDP

; bc = nr of bytes to skip
; ix = this
; Modifies: hl, a
FileReader_Skip:
	call FileReader_Read
	dec bc
	ld a,b
	or c
	jr nz,FileReader_Skip
	ret

; ix = this
FileReader_ReadFromFile: PROC
	ld b,(ix + FileReader.fileHandle)
	ld e,(ix + FileReader.bufferStart)
	ld d,(ix + FileReader.bufferStart + 1)
	ld l,(ix + FileReader.bufferEnd)
	ld h,(ix + FileReader.bufferEnd + 1)
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
