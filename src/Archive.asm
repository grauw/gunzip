;
; Gzip archive
;
Archive_FHCRC: equ 1 << 1;
Archive_FEXTRA: equ 1 << 2;
Archive_FNAME: equ 1 << 3;
Archive_FCOMMENT: equ 1 << 4;

Archive: MACRO
	inflate:
		dw Inflate_instance
	inputFileHandle:
		db 0FFH
	outputFileHandle:
		db 0FFH
	position:
		dw IBUFFER + IBUFFER_SIZE
	flags:
		db 0
	mtime:
		dd 0
	xfl:
		db 0
	os:
		db 0
	ENDM

; ix = this
; ix <- this
Archive_Constructor:
	push ix
	ld e,ixl
	ld d,ixh
	push de
	call Archive_GetInflate
	pop de
	call Inflate_Constructor
	pop ix
	ret

; ix = this
; ix <- this
Archive_Destructor:
	push ix
	call Archive_GetInflate
	call Inflate_Destructor
	pop ix
	ret

; ix = this
; de <- Inflate implementation
; ix <- Inflate implementation
Archive_GetInflate:
	ld e,(ix + Archive.inflate)
	ld d,(ix + Archive.inflate + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
; a <- value
; Modifies: hl
Archive_Read: PROC
	ld l,(ix + Archive.position)
	ld h,(ix + Archive.position + 1)
	bit 6,h
	call nz,NextBlock
	ld a,(hl)
	inc hl
	ld (ix + Archive.position),l
	ld (ix + Archive.position + 1),h
	ret
NextBlock:
	push bc
	push de
	ld b,(ix + Archive.inputFileHandle)
	ld hl,IBUFFER_SIZE
	ld de,IBUFFER
	ld c,_READ
	call BDOS
	call Gunzip_CheckDOSError
	pop de
	pop bc
	ld hl,IBUFFER
	ret
	ENDP

; ix = this
; de <- value
; Modifies: hl, a
Archive_ReadWord:
	call Archive_Read
	ld e,a
	call Archive_Read
	ld d,a
	ret

; bx = bytes to skip
; ix = this
; Modifies: hl
Archive_Skip:
	ld l,(ix + Archive.position)
	ld h,(ix + Archive.position + 1)
	add hl,bc
	ld (ix + Archive.position),l
	ld (ix + Archive.position + 1),h
	ret

; de = source address
; hl = nr of bytes
; ix = this
Archive_WriteToOutput:
	ld b,(ix + Archive.outputFileHandle)
	ld c,_WRITE
	call BDOS
	call Gunzip_CheckDOSError
	ret

; hl = input archive path
; de = output file path
; ix = this
Archive_Inflate:
	push de
	ex de,hl
	ld a,00000001B  ; read only
	ld c,_OPEN
	call BDOS
	call Gunzip_CheckDOSError
	ld (ix + Archive.inputFileHandle),b
	pop de
	ld a,00000010B  ; write only
	ld b,0
	ld c,_CREATE
	call BDOS
	call Gunzip_CheckDOSError
	ld (ix + Archive.outputFileHandle),b

	call Archive_Process

	ld b,(ix + Archive.inputFileHandle)
	ld c,_CLOSE
	call BDOS
	call Gunzip_CheckDOSError
	ld b,(ix + Archive.outputFileHandle)
	ld c,_CLOSE
	call BDOS
	call Gunzip_CheckDOSError
	ret

; hl = file size
; ix = this
Archive_Process:
	call Archive_Read
	cp 31  ; gzip signature (1)
	ld hl,Archive_notGzipError
	jp nz,Gunzip_TerminateWithError
	call Archive_Read
	cp 139  ; gzip signature (1)
	ld hl,Archive_notGzipError
	jp nz,Gunzip_TerminateWithError
	call Archive_Read
	cp 8  ; deflate compression ID (1)
	ld hl,Archive_notDeflateError
	jp nz,Gunzip_TerminateWithError

	call Archive_Read
	ld (ix + Archive.flags),a
	call Archive_Read
	ld (ix + Archive.mtime),a
	call Archive_Read
	ld (ix + Archive.mtime + 1),a
	call Archive_Read
	ld (ix + Archive.mtime + 2),a
	call Archive_Read
	ld (ix + Archive.mtime + 3),a
	call Archive_Read
	ld (ix + Archive.xfl),a
	call Archive_Read
	ld (ix + Archive.os),a

	ld a,(ix + Archive.flags)
	and Archive_FEXTRA
	call nz,Archive_SkipExtra

	ld a,(ix + Archive.flags)
	and Archive_FNAME
	call nz,Archive_SkipName

	ld a,(ix + Archive.flags)
	and Archive_FCOMMENT
	call nz,Archive_SkipComment

	ld a,(ix + Archive.flags)
	and Archive_FHCRC
	call nz,Archive_SkipHeaderCRC

	push ix
	call Archive_GetInflate
	call Inflate_Inflate
	pop ix
	ret

; ix = this
Archive_SkipExtra:
	call Archive_Read
	ld c,a
	call Archive_Read
	ld b,a
	call Archive_Skip
	ret

; ix = this
Archive_SkipName:
	call Archive_Read
	and a
	jp nz,Archive_SkipName
	ret

; ix = this
Archive_SkipComment:
	call Archive_Read
	and a
	jp nz,Archive_SkipComment
	ret

; ix = this
Archive_SkipHeaderCRC:
	call Archive_Read
	call Archive_Read
	ret

;
	SECTION RAM

Archive_instance: Archive

Archive_notGzipError:
	db "Not a GZIP file.",13,10,0

Archive_notDeflateError:
	db "Not compressed with DEFLATE.",13,10,0

	ENDS
