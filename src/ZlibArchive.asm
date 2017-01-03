;
; Zlib archive
;
ZlibArchive_DEFLATE_ID: equ 8
ZlibArchive_MAX_WINDOW: equ 7

ZlibArchive: MACRO
	reader:
		dw 0
	inflate:
		dw 0
	adler32CheckEnabled:
		db 0
	adler32Checker:
		dw 0
	cm:
		db 0
	cinfo:
		dd 0
	flevel:
		dd 0
	adler32:
		dd 0
	_size:
	ENDM

ZlibArchive_class: Class ZlibArchive, ZlibArchive_template, Heap_main
ZlibArchive_template: ZlibArchive

; a = -1: Adler32 check enabled, 0: disabled
; de = reader
; ix = this
; ix <- this
; de <- this
ZlibArchive_Construct:
	ld (ix + ZlibArchive.reader),e
	ld (ix + ZlibArchive.reader + 1),d
	ld (ix + ZlibArchive.adler32CheckEnabled),a
	call ZlibArchive_ReadHeader
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
ZlibArchive_Destruct:
	ret

; ix = this
; de <- file reader
; iy <- file reader
ZlibArchive_GetReaderIY:
	ld e,(ix + ZlibArchive.reader)
	ld d,(ix + ZlibArchive.reader + 1)
	ld iyl,e
	ld iyh,d
	ret

; ix = this
; de <- Inflate implementation
; ix <- Inflate implementation
ZlibArchive_GetInflate:
	ld e,(ix + ZlibArchive.inflate)
	ld d,(ix + ZlibArchive.inflate + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
ZlibArchive_ReadHeader:
	call ZlibArchive_GetReaderIY
	call Reader_ReadWordBE_IY
	call ZlibArchive_CheckFCHECK
	ld hl,ZlibArchive_invalidFCHECKError
	jp nz,System_TerminateWithError
	ld a,d
	and 00001111B
	cp ZlibArchive_DEFLATE_ID
	ld hl,ZlibArchive_notDeflateError
	jp nz,System_TerminateWithError
	ld (ix + ZlibArchive.cm),a
	ld a,d
	and 11110000B
	rrca
	rrca
	rrca
	rrca
	cp ZlibArchive_MAX_WINDOW + 1
	ld hl,ZlibArchive_invalidWindowError
	jp nc,System_TerminateWithError
	ld (ix + ZlibArchive.cinfo),a
	ld a,e
	and 00100000B
	ld hl,ZlibArchive_unsupportedPresetDictionaryError
	jp nz,System_TerminateWithError
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
	ld (ix + ZlibArchive.adler32),l
	ld (ix + ZlibArchive.adler32 + 1),h
	ld (ix + ZlibArchive.adler32 + 2),e
	ld (ix + ZlibArchive.adler32 + 3),d
	ret

; de = writer (min 32K)
; ix = this
ZlibArchive_Extract:
	bit 0,(ix + ZlibArchive.adler32CheckEnabled)
	call nz,ZlibArchive_CreateAdler32Checker
	call ZlibArchive_CreateInflate
	call ZlibArchive_Inflate
	call ZlibArchive_ReadFooter
	call ZlibArchive_Verify
	call ZlibArchive_DestroyInflate
	bit 0,(ix + ZlibArchive.adler32CheckEnabled)
	call nz,ZlibArchive_DestroyAdler32Checker
	ret

; de = writer (min 32K)
; ix = this
ZlibArchive_CreateInflate:
	ld l,(ix + ZlibArchive.reader)
	ld h,(ix + ZlibArchive.reader + 1)
	push ix
	call Inflate_class.New
	call Inflate_Construct
	pop ix
	ld (ix + ZlibArchive.inflate),e
	ld (ix + ZlibArchive.inflate + 1),d
	ret

; ix = this
ZlibArchive_DestroyInflate:
	push ix
	call ZlibArchive_GetInflate
	call Inflate_Destruct
	call Inflate_class.Delete
	pop ix
	ld (ix + ZlibArchive.inflate),0
	ld (ix + ZlibArchive.inflate + 1),0
	ret

; de = writer (min 32K)
; ix = this
ZlibArchive_CreateAdler32Checker:
	push de
	push ix
	call Adler32Checker_class.New
	call Adler32Checker_Construct
	pop ix
	ld (ix + ZlibArchive.adler32Checker),e
	ld (ix + ZlibArchive.adler32Checker + 1),d
	pop de
	ret

; de = writer (min 32K)
; ix = this
ZlibArchive_DestroyAdler32Checker:
	ld e,(ix + ZlibArchive.adler32Checker)
	ld d,(ix + ZlibArchive.adler32Checker + 1)
	push ix
	ld ixl,e
	ld ixh,d
	call Adler32Checker_Destruct
	call Adler32Checker_class.Delete
	pop ix
	ret

; ix = this
ZlibArchive_Inflate:
	push ix
	call ZlibArchive_GetInflate
	call Inflate_Inflate
	pop ix
	ret

; ix = this
ZlibArchive_Verify:
	call ZlibArchive_VerifyAdler32
	ld hl,ZlibArchive_adler32MismatchError
	jp nz,System_TerminateWithError
	ret

; ix = this
; f <- nz: mismatch
ZlibArchive_VerifyAdler32:
	bit 0,(ix + ZlibArchive.adler32CheckEnabled)
	ret z
	ld e,(ix + ZlibArchive.adler32Checker)
	ld d,(ix + ZlibArchive.adler32Checker + 1)
	push de
	ld e,(ix + ZlibArchive.adler32)
	ld d,(ix + ZlibArchive.adler32 + 1)
	ld c,(ix + ZlibArchive.adler32 + 2)
	ld b,(ix + ZlibArchive.adler32 + 3)
	ex (sp),ix
	call Adler32Checker_VerifyAdler32
	pop ix
	ret

;
ZlibArchive_invalidFCHECKError:
	db "Invalid FCHECK.",13,10,0

ZlibArchive_notDeflateError:
	db "Not compressed with DEFLATE.",13,10,0

ZlibArchive_invalidWindowError:
	db "Invalid window size.",13,10,0

ZlibArchive_unsupportedPresetDictionaryError:
	db "Unsupported preset dictionary.",13,10,0

ZlibArchive_adler32MismatchError:
	db "Inflated Adler32 checksum mismatch.",13,10,0
