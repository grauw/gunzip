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
	reader:
		dw FileReader_instance
	writer:
		dw FileWriter_instance
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
	call Archive_GetReader
	ld hl,IBUFFER
	ld bc,IBUFFER_SIZE
	call FileReader_Constructor
	pop ix
	push ix
	call Archive_GetWriter
	ld hl,OBUFFER
	ld bc,OBUFFER_SIZE
	call FileWriter_Constructor
	pop ix
	push ix
	ld l,(ix + Archive.reader)
	ld h,(ix + Archive.reader + 1)
	ld e,(ix + Archive.writer)
	ld d,(ix + Archive.writer + 1)
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
	push ix
	call Archive_GetReader
	call FileReader_Destructor
	pop ix
	push ix
	call Archive_GetWriter
	call FileWriter_Destructor
	pop ix
	ret

; ix = this
; de <- file reader
; ix <- file reader
Archive_GetReader:
	ld e,(ix + Archive.reader)
	ld d,(ix + Archive.reader + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
; de <- file writer
; ix <- file writer
Archive_GetWriter:
	ld e,(ix + Archive.writer)
	ld d,(ix + Archive.writer + 1)
	ld ixl,e
	ld ixh,d
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
Archive_Read:
	push ix
	call Archive_GetReader
	call FileReader_Read
	pop ix
	ret

; bx = bytes to skip
; ix = this
; Modifies: hl
Archive_Skip:
	push ix
	call Archive_GetReader
	call FileReader_Skip
	pop ix
	ret

; hl = input archive path
; de = output file path
; ix = this
Archive_Inflate:
	push de
	push ix
	call Archive_GetReader
	ex de,hl
	call FileReader_Open
	pop ix
	pop hl
	push ix
	call Archive_GetWriter
	ex de,hl
	call FileWriter_Open
	pop ix

	call Archive_Process

	push ix
	call Archive_GetReader
	call FileReader_Close
	pop ix
	push ix
	call Archive_GetWriter
	call FileWriter_Close
	pop ix
	ret

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
