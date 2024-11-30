;
; Gzip archive
;
GzipArchive_STATE_CHECKSUM_BIT: equ 0
GzipArchive_SIGNATURE_1: equ 1FH
GzipArchive_SIGNATURE_2: equ 8BH
GzipArchive_DEFLATE_ID: equ 8
GzipArchive_FTEXT: equ 1 << 0
GzipArchive_FHCRC: equ 1 << 1
GzipArchive_FEXTRA: equ 1 << 2
GzipArchive_FNAME: equ 1 << 3
GzipArchive_FCOMMENT: equ 1 << 4
GzipArchive_RESERVED: equ 1 << 5 | 1 << 6 | 1 << 7

GzipArchive: MACRO
	state:
		db 0
	reader:
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
		IF GZIP_CRC32
		dd 0
		ENDIF
	inflate:
		Inflate
	crc32Checker:
		IF GZIP_CRC32
		CRC32Checker
		ENDIF
	_size:
	ENDM

; a = -1: CRC32 check enabled, 0: disabled
; de = reader
; ix = this
; ix <- this
GzipArchive_Construct:
	IF GZIP_CRC32
	and 1 << GzipArchive_STATE_CHECKSUM_BIT
	ELSE
	xor a
	ENDIF
	ld (ix + GzipArchive.state),a
	ld (ix + GzipArchive.reader),e
	ld (ix + GzipArchive.reader + 1),d
	jp GzipArchive_ReadHeader

; ix = this
; iy <- file reader
; Modifies: de
GzipArchive_GetReaderIY:
	ld e,(ix + GzipArchive.reader)
	ld d,(ix + GzipArchive.reader + 1)
	ld iyl,e
	ld iyh,d
	ret

; ix = this
; ix <- Inflate implementation
; Modifies: f
GzipArchive_GetInflate:
	push de
	ld de,GzipArchive.inflate
	add ix,de
	pop de
	ret

; ix = this
GzipArchive_ReadHeader:
	call GzipArchive_GetReaderIY
	call Reader_Read_IY
	cp GzipArchive_SIGNATURE_1
	ld hl,GzipArchive_notGzipError
	jp nz,System_ThrowExceptionWithMessage
	call Reader_Read_IY
	cp GzipArchive_SIGNATURE_2
	ld hl,GzipArchive_notGzipError
	jp nz,System_ThrowExceptionWithMessage
	call Reader_Read_IY
	cp GzipArchive_DEFLATE_ID
	jp nz,System_ThrowException  ; not DEFLATE

	call Reader_Read_IY
	ld (ix + GzipArchive.flags),a
	call Reader_ReadDoubleWord_IY
	ld (ix + GzipArchive.mtime),l
	ld (ix + GzipArchive.mtime + 1),h
	ld (ix + GzipArchive.mtime + 2),e
	ld (ix + GzipArchive.mtime + 3),d
	call Reader_Read_IY
	ld (ix + GzipArchive.xfl),a
	call Reader_Read_IY
	ld (ix + GzipArchive.os),a

	ld a,(ix + GzipArchive.flags)
	and GzipArchive_RESERVED
	jp nz,System_ThrowException  ; unknown flag

	ld a,(ix + GzipArchive.flags)
	and GzipArchive_FEXTRA
	call nz,GzipArchive_SkipExtra

	ld a,(ix + GzipArchive.flags)
	and GzipArchive_FNAME
	call nz,GzipArchive_SkipASCIIZ

	ld a,(ix + GzipArchive.flags)
	and GzipArchive_FCOMMENT
	call nz,GzipArchive_SkipASCIIZ

	ld a,(ix + GzipArchive.flags)
	and GzipArchive_FHCRC
	call nz,GzipArchive_SkipHeaderCRC
	ret

; ix = this
GzipArchive_ReadFooter:
	call GzipArchive_GetReaderIY
	call Reader_ReadDoubleWord_IY
	IF GZIP_CRC32
	ld (ix + GzipArchive.crc32),l
	ld (ix + GzipArchive.crc32 + 1),h
	ld (ix + GzipArchive.crc32 + 2),e
	ld (ix + GzipArchive.crc32 + 3),d
	ENDIF
	call Reader_ReadDoubleWord_IY
	ld (ix + GzipArchive.isize),l
	ld (ix + GzipArchive.isize + 1),h
	ld (ix + GzipArchive.isize + 2),e
	ld (ix + GzipArchive.isize + 3),d
	ret

; bc = decoders buffer
; de = writer (min 32K)
; ix = this
GzipArchive_Extract:
	IF GZIP_CRC32
	push bc
	bit GzipArchive_STATE_CHECKSUM_BIT,(ix + GzipArchive.state)
	call nz,GzipArchive_CreateCRC32Checker
	pop bc
	ENDIF
	call GzipArchive_CreateInflate
	call GzipArchive_Inflate
	call GzipArchive_ReadFooter
	call GzipArchive_Verify
	ret

; bc = decoders buffer
; de = writer (min 32K)
; ix = this
GzipArchive_CreateInflate:
	ld l,(ix + GzipArchive.reader)
	ld h,(ix + GzipArchive.reader + 1)
	push ix
	call GzipArchive_GetInflate
	call Inflate_Construct
	pop ix
	ret

	IF GZIP_CRC32

; de = writer (min 32K)
; ix = this
GzipArchive_CreateCRC32Checker:
	push de
	push ix
	ld bc,GzipArchive.crc32Checker
	add ix,bc
	call CRC32Checker_Construct
	pop ix
	pop de
	ret

	ENDIF

; ix = this
GzipArchive_Inflate:
	push ix
	call GzipArchive_GetInflate
	call Inflate_Inflate
	pop ix
	ret

; ix = this
GzipArchive_Verify:
	call GzipArchive_VerifyISIZE
	ld hl,GzipArchive_isizeMismatchError
	jp nz,System_ThrowExceptionWithMessage

	IF GZIP_CRC32
	call GzipArchive_VerifyCRC32
	ld hl,GzipArchive_crc32MismatchError
	jp nz,System_ThrowExceptionWithMessage
	ENDIF
	ret

; ix = this
GzipArchive_SkipExtra:
	call GzipArchive_GetReaderIY
	call Reader_ReadWord_IY
	ld c,e
	ld b,d
	jp Reader_Skip_IY

; ix = this
GzipArchive_SkipASCIIZ: PROC
	call GzipArchive_GetReaderIY
Loop:
	call Reader_Read_IY
	and a
	jp nz,Loop
	ret
	ENDP

; ix = this
GzipArchive_SkipHeaderCRC:
	call GzipArchive_GetReaderIY
	jp Reader_ReadWord_IY

; ix = this
; f <- nz: mismatch
GzipArchive_VerifyISIZE:
	push ix
	call GzipArchive_GetInflate
	call Inflate_GetWriter
	call Writer_GetCount
	pop ix
	ld a,e
	cp (ix + GzipArchive.isize)
	ret nz
	ld a,d
	cp (ix + GzipArchive.isize + 1)
	ret nz
	ld a,c
	cp (ix + GzipArchive.isize + 2)
	ret nz
	ld a,b
	cp (ix + GzipArchive.isize + 3)
	ret

	IF GZIP_CRC32

; ix = this
; f <- nz: mismatch
GzipArchive_VerifyCRC32:
	bit GzipArchive_STATE_CHECKSUM_BIT,(ix + GzipArchive.state)
	ret z
	ld l,(ix + GzipArchive.crc32)
	ld h,(ix + GzipArchive.crc32 + 1)
	ld c,(ix + GzipArchive.crc32 + 2)
	ld b,(ix + GzipArchive.crc32 + 3)
	push ix
	ld de,GzipArchive.crc32Checker
	add ix,de
	ex de,hl
	call CRC32Checker_VerifyCRC32
	pop ix
	ret

	ENDIF

;
GzipArchive_notGzipError:
	db "Not a GZIP file.",13,10,0

GzipArchive_isizeMismatchError:
	db "Inflated size mismatch.",13,10,0

	IF GZIP_CRC32

GzipArchive_crc32MismatchError:
	db "Inflated CRC32 mismatch.",13,10,0

	ENDIF
