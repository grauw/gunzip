;
; Inflate implementation
;
Inflate: MACRO
	reader:
		dw 0
	writer:
		dw 0
	byte:
		db 0
	bitCounter:
		db 1
	isize:
		dd 0
	crc32:
		dd 0FFFFFFFFH
	_size:
	ENDM

Inflate_class: Class Inflate, Inflate_template, Inflate_Constructor, Inflate_Destructor, Heap_main
Inflate_template: Inflate

; hl = file reader
; de = file writer
; ix = this
; ix <- this
Inflate_Constructor:
	ld (ix + Inflate.reader),l
	ld (ix + Inflate.reader + 1),h
	ld (ix + Inflate.writer),e
	ld (ix + Inflate.writer + 1),d
	ret

; ix = this
; ix <- this
Inflate_Destructor:
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
; de <- file writer
; ix <- file writer
Inflate_GetWriter:
	ld e,(ix + Inflate.writer)
	ld d,(ix + Inflate.writer + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
; a <- value
; Modifies: hl, de
Inflate_Read:
	push ix
	call Inflate_GetReader
	call FileReader_Read
	pop ix
	ret

; ix = this
; de <- value
; Modifies: hl, de, a
Inflate_ReadWord:
	push ix
	call Inflate_GetReader
	call FileReader_Read
	ld e,a
	call FileReader_Read
	ld d,a
	pop ix
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
; ix = this
; Modifies: hl, de
Inflate_Write:
	call Inflate_IncreaseISIZE
	call Inflate_UpdateCRC32
	push ix
	call Inflate_GetWriter
	call FileWriter_Write
	pop ix
	ret

; ix = this
Inflate_IncreaseISIZE:
	inc (ix + Inflate.isize)
	ret nz
	inc (ix + Inflate.isize + 1)
	ret nz
	inc (ix + Inflate.isize + 2)
	ret nz
	inc (ix + Inflate.isize + 3)
	ret

; a = value
; ix = this
; Modifies: hl, de
Inflate_UpdateCRC32:
	push af
	xor (ix + Inflate.crc32)
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	ld de,CRC32Table
	add hl,de
	ld a,(hl)
	xor (ix + Inflate.crc32 + 1)
	ld (ix + Inflate.crc32),a
	inc l
	ld a,(hl)
	xor (ix + Inflate.crc32 + 2)
	ld (ix + Inflate.crc32 + 1),a
	inc l
	ld a,(hl)
	xor (ix + Inflate.crc32 + 3)
	ld (ix + Inflate.crc32 + 2),a
	inc l
	ld a,(hl)
	ld (ix + Inflate.crc32 + 3),a
	pop af
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
	jp Application_TerminateWithError

; ix = this
Inflate_InflateUncompressed: PROC
	call Inflate_Align
	call Inflate_ReadWord
	push de
	push de
	call Inflate_ReadWord
	pop hl
	scf
	adc hl,de
	ld hl,Inflate_invalidLengthError
	jp nz,Application_TerminateWithError
	pop de
	ld a,d
	or e
	ret z
	ld b,e
	dec de
	inc d
	ld c,d
Loop:
	call Inflate_Read
	call Inflate_Write
	djnz Loop
	dec c
	jp nz,Loop
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
Inflate_invalidBlockTypeError:
	db "Invalid block type.",13,10,0

Inflate_invalidLengthError:
	db "Invalid length.",13,10,0
