;
; Gzip archive
;
Archive_SIGNATURE_1: equ 1FH
Archive_SIGNATURE_2: equ 8BH
Archive_DEFLATE_ID: equ 8
Archive_FTEXT: equ 1 << 0;
Archive_FHCRC: equ 1 << 1;
Archive_FEXTRA: equ 1 << 2;
Archive_FNAME: equ 1 << 3;
Archive_FCOMMENT: equ 1 << 4;
Archive_RESERVED: equ 1 << 5 | 1 << 6 | 1 << 7;

Archive: MACRO
	reader:
		dw 0
	inflate:
		dw 0
	crc32Checker:
		dw 0
	flags:
		db 0
	mtime:
		dd 0
	xfl:
		db 0
	os:
		db 0
	isize:
		dd 0
	crc32:
		dd 0
	_size:
	ENDM

Archive_class: Class Archive, Archive_template, Heap_main
Archive_template: Archive

; de = reader
; ix = this
; ix <- this
; de <- this
Archive_Construct:
	ld (ix + Archive.reader),e
	ld (ix + Archive.reader + 1),d
	call Archive_ReadHeader
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
Archive_Destruct:
	ret

; ix = this
; de <- file reader
; iy <- file reader
Archive_GetReaderIY:
	ld e,(ix + Archive.reader)
	ld d,(ix + Archive.reader + 1)
	ld iyl,e
	ld iyh,d
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
Archive_ReadHeader:
	call Archive_GetReaderIY
	call Reader_Read_IY
	cp Archive_SIGNATURE_1
	ld hl,Archive_notGzipError
	jp nz,Application_TerminateWithError
	call Reader_Read_IY
	cp Archive_SIGNATURE_2
	ld hl,Archive_notGzipError
	jp nz,Application_TerminateWithError
	call Reader_Read_IY
	cp Archive_DEFLATE_ID
	ld hl,Archive_notDeflateError
	jp nz,Application_TerminateWithError

	call Reader_Read_IY
	ld (ix + Archive.flags),a
	call Reader_ReadDoubleWord_IY
	ld (ix + Archive.mtime),l
	ld (ix + Archive.mtime + 1),h
	ld (ix + Archive.mtime + 2),e
	ld (ix + Archive.mtime + 3),d
	call Reader_Read_IY
	ld (ix + Archive.xfl),a
	call Reader_Read_IY
	ld (ix + Archive.os),a

	ld a,(ix + Archive.flags)
	and Archive_RESERVED
	ld hl,Archive_unknownFlagError
	jp nz,Application_TerminateWithError

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
	ret

; ix = this
Archive_ReadFooter:
	call Archive_GetReaderIY
	call Reader_ReadDoubleWord_IY
	ld (ix + Archive.crc32),l
	ld (ix + Archive.crc32 + 1),h
	ld (ix + Archive.crc32 + 2),e
	ld (ix + Archive.crc32 + 3),d
	call Reader_ReadDoubleWord_IY
	ld (ix + Archive.isize),l
	ld (ix + Archive.isize + 1),h
	ld (ix + Archive.isize + 2),e
	ld (ix + Archive.isize + 3),d
	ret

; f = z: enable CRC32 check
; de = writer (min 32K)
; ix = this
Archive_Extract:
	call z,Archive_CreateCRC32Checker
	call Archive_CreateInflate
	call Archive_Inflate
	call Archive_ReadFooter
	call Archive_Verify
	call Archive_DestroyInflate
	call Archive_DestroyCRC32Checker
	ret

; de = writer (min 32K)
; ix = this
Archive_CreateInflate:
	ld l,(ix + Archive.reader)
	ld h,(ix + Archive.reader + 1)
	push ix
	call Inflate_class.New
	call Inflate_Construct
	pop ix
	ld (ix + Archive.inflate),e
	ld (ix + Archive.inflate + 1),d
	ret

; ix = this
Archive_DestroyInflate:
	push ix
	call Archive_GetInflate
	call Inflate_Destruct
	call Inflate_class.Delete
	pop ix
	ld (ix + Archive.inflate),0
	ld (ix + Archive.inflate + 1),0
	ret

; de = writer (min 32K)
; ix = this
Archive_CreateCRC32Checker:
	push de
	push ix
	call CRC32Checker_class.New
	call CRC32Checker_Construct
	pop ix
	ld (ix + Archive.crc32Checker),e
	ld (ix + Archive.crc32Checker + 1),d
	pop de
	ret

; de = writer (min 32K)
; ix = this
Archive_DestroyCRC32Checker:
	ld e,(ix + Archive.crc32Checker)
	ld d,(ix + Archive.crc32Checker + 1)
	ld a,e
	or d
	ret z
	push ix
	ld ixl,e
	ld ixh,d
	call CRC32Checker_Destruct
	call CRC32Checker_class.Delete
	pop ix
	ret

; ix = this
Archive_Inflate:
	push ix
	call Archive_GetInflate
	call Inflate_Inflate
	pop ix
	ret

; ix = this
Archive_Verify:
	call Archive_VerifyISIZE
	ld hl,Archive_isizeMismatchError
	jp nz,Application_TerminateWithError

	call Archive_VerifyCRC32
	ld hl,Archive_crc32MismatchError
	jp nz,Application_TerminateWithError
	ret

; ix = this
Archive_SkipExtra:
	call Archive_GetReaderIY
	call Reader_ReadWord_IY
	ld c,e
	ld b,d
	call Reader_Skip_IY
	ret

; ix = this
Archive_SkipName: PROC
	call Archive_GetReaderIY
Loop:
	call Reader_Read_IY
	and a
	jp nz,Loop
	ret
	ENDP

; ix = this
Archive_SkipComment: PROC
	call Archive_GetReaderIY
Loop:
	call Reader_Read_IY
	and a
	jp nz,Loop
	ret
	ENDP

; ix = this
Archive_SkipHeaderCRC:
	call Archive_GetReaderIY
	call Reader_ReadWord_IY
	ret

; ix = this
; f <- nz: mismatch
Archive_VerifyISIZE:
	push ix
	call Archive_GetInflate
	call Inflate_GetWriter
	call Writer_GetCount
	pop ix
	ld a,e
	cp (ix + Archive.isize)
	ret nz
	ld a,d
	cp (ix + Archive.isize + 1)
	ret nz
	ld a,c
	cp (ix + Archive.isize + 2)
	ret nz
	ld a,b
	cp (ix + Archive.isize + 3)
	ret

; ix = this
; f <- nz: mismatch
Archive_VerifyCRC32:
	ld e,(ix + Archive.crc32Checker)
	ld d,(ix + Archive.crc32Checker + 1)
	ld a,e
	or d
	ret z
	push de
	ld e,(ix + Archive.crc32)
	ld d,(ix + Archive.crc32 + 1)
	ld c,(ix + Archive.crc32 + 2)
	ld b,(ix + Archive.crc32 + 3)
	ex (sp),ix
	call CRC32Checker_VerifyCRC32
	pop ix
	ret

;
Archive_notGzipError:
	db "Not a GZIP file.",13,10,0

Archive_notDeflateError:
	db "Not compressed with DEFLATE.",13,10,0

Archive_unknownFlagError:
	db "Unknown flag.",13,10,0

Archive_isizeMismatchError:
	db "Inflated size mismatch.",13,10,0

Archive_crc32MismatchError:
	db "Inflated CRC32 mismatch.",13,10,0
