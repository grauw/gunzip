;
; Zlib archive
;
ZlibArchive_DEFLATE_ID: equ 8
ZlibArchive_MAX_WINDOW: equ 7

ZlibArchive: MACRO
	reader:
		dw 0
	adler32CheckEnabled:
		IF ZLIB_ADLER32
		db 0
		ENDIF
	cm:
		db 0
	cinfo:
		dd 0
	flevel:
		dd 0
	adler32:
		IF ZLIB_ADLER32
		dd 0
		ENDIF
	inflate:
		Inflate
	adler32Checker:
		IF ZLIB_ADLER32
		Adler32Checker
		ENDIF
	_size:
	ENDM

; a = -1: Adler32 check enabled, 0: disabled
; de = reader
; ix = this
; ix <- this
ZlibArchive_Construct:
	ld (ix + ZlibArchive.reader),e
	ld (ix + ZlibArchive.reader + 1),d
	IF ZLIB_ADLER32
	ld (ix + ZlibArchive.adler32CheckEnabled),a
	ENDIF
	call ZlibArchive_ReadHeader
	ret

; ix = this
; iy <- file reader
; Modifies: de
ZlibArchive_GetReaderIY:
	ld e,(ix + ZlibArchive.reader)
	ld d,(ix + ZlibArchive.reader + 1)
	ld iyl,e
	ld iyh,d
	ret

; ix = this
; ix <- Inflate implementation
; Modifies: f
ZlibArchive_GetInflate:
	push de
	ld de,ZlibArchive.inflate
	add ix,de
	pop de
	ret

; ix = this
ZlibArchive_ReadHeader:
	call ZlibArchive_GetReaderIY
	call Reader_ReadWordBE_IY
	call ZlibArchive_CheckFCHECK
	ld hl,ZlibArchive_invalidFCHECKError
	jp nz,System_ThrowExceptionWithMessage
	ld a,d
	and 00001111B
	cp ZlibArchive_DEFLATE_ID
	ld hl,ZlibArchive_notDeflateError
	jp nz,System_ThrowExceptionWithMessage
	ld (ix + ZlibArchive.cm),a
	ld a,d
	and 11110000B
	rrca
	rrca
	rrca
	rrca
	cp ZlibArchive_MAX_WINDOW + 1
	ld hl,ZlibArchive_invalidWindowError
	jp nc,System_ThrowExceptionWithMessage
	ld (ix + ZlibArchive.cinfo),a
	ld a,e
	and 00100000B
	ld hl,ZlibArchive_unsupportedPresetDictionaryError
	jp nz,System_ThrowExceptionWithMessage
	ld a,e
	and 11000000B
	rlca
	rlca
	ld (ix + ZlibArchive.flevel),a
	ret

; d = CMF
; e = FLG
; f <- nz: invalid
; Modifies: af, bc, hl
ZlibArchive_CheckFCHECK: PROC
	ld l,e
	ld h,d
	ld c,31
	xor a
	ld b,16
Loop:
	add hl,hl
	rla
	cp c
	jr c,NoAdd
	sub c
	inc l
NoAdd:
	djnz Loop
	and a
	ret
	ENDP

; ix = this
ZlibArchive_ReadFooter:
	call ZlibArchive_GetReaderIY
	call Reader_ReadDoubleWordBE_IY
	IF ZLIB_ADLER32
	ld (ix + ZlibArchive.adler32),l
	ld (ix + ZlibArchive.adler32 + 1),h
	ld (ix + ZlibArchive.adler32 + 2),e
	ld (ix + ZlibArchive.adler32 + 3),d
	ENDIF
	ret

; bc = decoders buffer
; de = writer (min 32K)
; ix = this
ZlibArchive_Extract:
	IF ZLIB_ADLER32
	push bc
	bit 0,(ix + ZlibArchive.adler32CheckEnabled)
	call nz,ZlibArchive_CreateAdler32Checker
	pop bc
	ENDIF
	call ZlibArchive_CreateInflate
	call ZlibArchive_Inflate
	call ZlibArchive_ReadFooter
	call ZlibArchive_Verify
	ret

; bc = decoders buffer
; de = writer (min 32K)
; ix = this
ZlibArchive_CreateInflate:
	ld l,(ix + ZlibArchive.reader)
	ld h,(ix + ZlibArchive.reader + 1)
	push ix
	call ZlibArchive_GetInflate
	call Inflate_Construct
	pop ix
	ret

	IF ZLIB_ADLER32

; de = writer (min 32K)
; ix = this
ZlibArchive_CreateAdler32Checker:
	push de
	push ix
	ld bc,ZlibArchive.adler32Checker
	add ix,bc
	call Adler32Checker_Construct
	pop ix
	pop de
	ret

	ENDIF

; ix = this
ZlibArchive_Inflate:
	push ix
	call ZlibArchive_GetInflate
	call Inflate_Inflate
	pop ix
	ret

; ix = this
ZlibArchive_Verify:
	IF ZLIB_ADLER32
	call ZlibArchive_VerifyAdler32
	ld hl,ZlibArchive_adler32MismatchError
	jp nz,System_ThrowExceptionWithMessage
	ENDIF
	ret

	IF ZLIB_ADLER32

; ix = this
; f <- nz: mismatch
ZlibArchive_VerifyAdler32:
	bit 0,(ix + ZlibArchive.adler32CheckEnabled)
	ret z
	ld l,(ix + ZlibArchive.adler32)
	ld h,(ix + ZlibArchive.adler32 + 1)
	ld c,(ix + ZlibArchive.adler32 + 2)
	ld b,(ix + ZlibArchive.adler32 + 3)
	push ix
	ld de,ZlibArchive.adler32Checker
	add ix,de
	ex de,hl
	call Adler32Checker_VerifyAdler32
	pop ix
	ret

	ENDIF

;
ZlibArchive_invalidFCHECKError:
	db "Invalid FCHECK.",13,10,0

ZlibArchive_notDeflateError:
	db "Not compressed with DEFLATE.",13,10,0

ZlibArchive_invalidWindowError:
	db "Invalid window size.",13,10,0

ZlibArchive_unsupportedPresetDictionaryError:
	db "Unsupported preset dictionary.",13,10,0

	IF ZLIB_ADLER32

ZlibArchive_adler32MismatchError:
	db "Inflated Adler32 checksum mismatch.",13,10,0

	ENDIF
