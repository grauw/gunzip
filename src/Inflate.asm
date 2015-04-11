;
; Inflate implementation
;
Inflate: MACRO
	archive:
		dw 0
	reader:
		dw 0
	output:
		dw OBUFFER
	byte:
		db 0
	bitCounter:
		db 1
	ENDM

; de = Gzip archive
; hl = file reader
; ix = this
; ix <- this
Inflate_Constructor:
	ld (ix + Inflate.archive),e
	ld (ix + Inflate.archive + 1),d
	ld (ix + Inflate.reader),l
	ld (ix + Inflate.reader + 1),h
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
; de <- file reader
; ix <- file reader
Inflate_GetReader:
	ld e,(ix + Inflate.reader)
	ld d,(ix + Inflate.reader + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
; f <- c: bit
Inflate_ReadBit: PROC
	dec (ix + Inflate.bitCounter)
	call z,NextByte
	srl (ix + Inflate.byte)
	ret
NextByte:
	push ix
	call Inflate_GetReader
	call FileReader_Read
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
	call Inflate_ReadBit
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
Inflate_Align:
	ld (ix + Inflate.bitCounter),1
	ret

; a = value
; iy = this
Inflate_IY_Write:
	ld l,(iy + Inflate.output)
	ld h,(iy + Inflate.output + 1)
	ld (hl),a
	inc hl
	ld (iy + Inflate.output),l
	ld (iy + Inflate.output + 1),h
	bit 7,h
	ret z
	bit 6,h
	ret z
	push af
	push bc
	push de
	call Inflate_IY_Flush
	pop de
	pop bc
	pop af
	ret

; ix = this
Inflate_Flush:
	push ix
	push ix
	pop iy
	call Inflate_IY_Flush
	pop ix
	ret

; ix = archive
; iy = this
Inflate_IY_Flush:
	ld e,(iy + Inflate.archive)
	ld d,(iy + Inflate.archive + 1)
	ld ixl,e
	ld ixh,d
	ld l,(iy + Inflate.output)
	ld h,(iy + Inflate.output + 1)
	ld de,OBUFFER
	and a
	sbc hl,de
	ld de,OBUFFER
	call Archive_WriteToOutput
	ld hl,OBUFFER
	ld (iy + Inflate.output),l
	ld (iy + Inflate.output + 1),h
	ret

; ix = this
Inflate_Inflate:
	call Inflate_ReadBit
	push af
	ld b,2
	call Inflate_ReadBits
	call Inflate_InflateBlock
	pop af
	jp nc,Inflate_Inflate
	call Inflate_Flush
	ret

; a = block type
; ix = this
Inflate_InflateBlock:
	and a
	jp z,Inflate_InflateUncompressed
	cp 2
	jp c,Inflate_InflateFixedCompressed
	jp z,Inflate_InflateDynamicCompressed
	ld hl,Inflate_invalidBlockTypeError
	jp Gunzip_TerminateWithError

; ix = this
Inflate_InflateUncompressed: PROC
	ld a,"0"
	call System_PrintChar
	call System_PrintCrLf
	call Inflate_Align
	push ix
	call Inflate_GetReader
	call FileReader_ReadWord
	push de
	push de
	call FileReader_ReadWord
	pop hl
	scf
	adc hl,de
	ld hl,Inflate_invalidLengthError
	jp nz,Gunzip_TerminateWithError
	pop de
	ld a,d
	or e
	jr z,Done
	pop iy
	push iy
	ld b,e
	dec de
	inc d
Loop:
	call FileReader_Read
	call Inflate_IY_Write
	djnz Loop
	dec d
	jp nz,Loop
Done:
	pop ix
	ret
	ENDP

; ix = this
Inflate_InflateFixedCompressed:
	ld a,"1"
	call System_PrintChar
	call System_PrintCrLf
	ld b,1
	ld c,_TERM
	call BDOS
	ret

; ix = this
Inflate_InflateDynamicCompressed:
	ld a,"2"
	call System_PrintChar
	call System_PrintCrLf
	ld b,1
	ld c,_TERM
	call BDOS
	ret

;
	SECTION RAM

Inflate_instance: Inflate

Inflate_invalidBlockTypeError:
	db "Invalid block type.",13,10,0

Inflate_invalidLengthError:
	db "Invalid length.",13,10,0

	ENDS
