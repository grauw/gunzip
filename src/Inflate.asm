;
; Inflate implementation
;
Inflate: MACRO
	archive:
		dw 0
	output:
		dw OBUFFER
	byte:
		db 0
	bitCounter:
		db 1
	ENDM

; de = Gzip archive
; ix = this
; ix <- this
Inflate_Constructor:
	ld (ix + Inflate.archive),e
	ld (ix + Inflate.archive + 1),d
	ret

; ix = this
; ix <- this
Inflate_Destructor:
	ret

; ix = this
; de <- Gzip archive
; iy <- Gzip archive
Inflate_GetArchive:
	ld e,(ix + Inflate.archive)
	ld d,(ix + Inflate.archive + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
; f <- c: bit
Inflate_Read: PROC
	dec (ix + Inflate.bitCounter)
	call z,NextByte
	srl (ix + Inflate.byte)
	ret
NextByte:
	push ix
	call Inflate_GetArchive
	call Archive_Read
	pop ix
	ld (ix + Inflate.byte),a
	ld (ix + Inflate.bitCounter),8
	ret
	ENDP

; b = nr of bits to read (1-8)
; ix = this
; a = value
Inflate_ReadBits: PROC
	ld a,9
	sub b
	call c,System_ThrowException
	call z,System_ThrowException
	ld c,a
	xor a
Loop1:
	call Inflate_Read
	rra
	djnz Loop1
	dec c
	ret z
	ld b,c
Loop2:
	rrca
	djnz Loop2
	ret
	ENDP

; ix = this
Inflate_Inflate:
	call Inflate_Read
	push af
	ld b,2
	call Inflate_ReadBits
	call Inflate_InflateBlock
	pop af
;	jp nc,Inflate_Inflate
	ret

; a = block type
; ix = this
Inflate_InflateBlock:
	and a
	jp z,Inflate_InflateUncompressed
	cp 2
	jp c,Inflate_InflateFixedCompressed
	jp z,Inflate_InflateDynamicCompressed
	ld hl,Archive_invalidBlockTypeError
	jp Gunzip_TerminateWithError

; ix = this
Inflate_InflateUncompressed:
	ld a,"0"
	call System_PrintChar
	call System_PrintCrLf
	ret

; ix = this
Inflate_InflateFixedCompressed:
	ld a,"1"
	call System_PrintChar
	call System_PrintCrLf
	ret

; ix = this
Inflate_InflateDynamicCompressed:
	ld a,"2"
	call System_PrintChar
	call System_PrintCrLf
	ret

;
	SECTION RAM

Inflate_instance: Inflate

Archive_invalidBlockTypeError:
	db "Invalid block type.",13,10,0

	ENDS
