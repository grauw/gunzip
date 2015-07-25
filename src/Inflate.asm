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
	_size:
	ENDM

Inflate_class: Class Inflate, Inflate_template, Heap_main
Inflate_template: Inflate

; hl = file reader
; de = file writer
; ix = this
; ix <- this
; de <- this
Inflate_Construct:
	ld (ix + Inflate.reader),l
	ld (ix + Inflate.reader + 1),h
	ld (ix + Inflate.writer),e
	ld (ix + Inflate.writer + 1),d
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
Inflate_Destruct:
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
	call Reader_Read
	pop ix
	ret

; ix = this
; de <- value
; Modifies: hl, de, a
Inflate_ReadWord:
	push ix
	call Inflate_GetReader
	call Reader_Read
	ld e,a
	call Reader_Read
	ld d,a
	pop ix
	ret

; ix = this
; f <- c: bit
Inflate_ReadBit:
	rr (ix + Inflate.byte)
	dec (ix + Inflate.bitCounter)
	ret nz
	push ix
	call Inflate_GetReader
	call Reader_Read
	pop ix
	rra
	ld (ix + Inflate.byte),a
	ld (ix + Inflate.bitCounter),8
	ret

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
; Modifies: af, hl
Inflate_Write:
	push ix
	call Inflate_GetWriter
	call Writer_Write
	pop ix
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

; Literal/length symbols 0-255
; ix = this
Inflate_WriteLiteral: REPT 256, ?value
	ld a,?value
	jp Inflate_Write
	ENDM

; Literal/length symbol 256
; ix = this
Inflate_EndBlock:
	ret

; Literal/length symbols 257-285
; ix = this
Inflate_CopyLength: REPT 29, ?value
	jp System_ThrowException
	ENDM

; Distance symbols 0-29
; ix = this
Inflate_CopyDistance: REPT 30, ?value
	jp System_ThrowException
	ENDM

;
Inflate_fixedLiteralLengthCodeLengths:
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8  ; 0-143: 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9  ; 144-255: 9
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 7, 7, 7, 7, 7, 7, 7, 7  ; 256-279: 7
	db 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8  ; 280-287: 8

Inflate_fixedLiteralLengthCodeLengthsCount: equ $ - Inflate_fixedLiteralLengthCodeLengths

Inflate_literalLengthSymbols:
	dw Inflate_WriteLiteral.0, Inflate_WriteLiteral.1, Inflate_WriteLiteral.2, Inflate_WriteLiteral.3
	dw Inflate_WriteLiteral.4, Inflate_WriteLiteral.5, Inflate_WriteLiteral.6, Inflate_WriteLiteral.7
	dw Inflate_WriteLiteral.8, Inflate_WriteLiteral.9, Inflate_WriteLiteral.10, Inflate_WriteLiteral.11
	dw Inflate_WriteLiteral.12, Inflate_WriteLiteral.13, Inflate_WriteLiteral.14, Inflate_WriteLiteral.15
	dw Inflate_WriteLiteral.16, Inflate_WriteLiteral.17, Inflate_WriteLiteral.18, Inflate_WriteLiteral.19
	dw Inflate_WriteLiteral.20, Inflate_WriteLiteral.21, Inflate_WriteLiteral.22, Inflate_WriteLiteral.23
	dw Inflate_WriteLiteral.24, Inflate_WriteLiteral.25, Inflate_WriteLiteral.26, Inflate_WriteLiteral.27
	dw Inflate_WriteLiteral.28, Inflate_WriteLiteral.29, Inflate_WriteLiteral.30, Inflate_WriteLiteral.31
	dw Inflate_WriteLiteral.32, Inflate_WriteLiteral.33, Inflate_WriteLiteral.34, Inflate_WriteLiteral.35
	dw Inflate_WriteLiteral.36, Inflate_WriteLiteral.37, Inflate_WriteLiteral.38, Inflate_WriteLiteral.39
	dw Inflate_WriteLiteral.40, Inflate_WriteLiteral.41, Inflate_WriteLiteral.42, Inflate_WriteLiteral.43
	dw Inflate_WriteLiteral.44, Inflate_WriteLiteral.45, Inflate_WriteLiteral.46, Inflate_WriteLiteral.47
	dw Inflate_WriteLiteral.48, Inflate_WriteLiteral.49, Inflate_WriteLiteral.50, Inflate_WriteLiteral.51
	dw Inflate_WriteLiteral.52, Inflate_WriteLiteral.53, Inflate_WriteLiteral.54, Inflate_WriteLiteral.55
	dw Inflate_WriteLiteral.56, Inflate_WriteLiteral.57, Inflate_WriteLiteral.58, Inflate_WriteLiteral.59
	dw Inflate_WriteLiteral.60, Inflate_WriteLiteral.61, Inflate_WriteLiteral.62, Inflate_WriteLiteral.63
	dw Inflate_WriteLiteral.64, Inflate_WriteLiteral.65, Inflate_WriteLiteral.66, Inflate_WriteLiteral.67
	dw Inflate_WriteLiteral.68, Inflate_WriteLiteral.69, Inflate_WriteLiteral.70, Inflate_WriteLiteral.71
	dw Inflate_WriteLiteral.72, Inflate_WriteLiteral.73, Inflate_WriteLiteral.74, Inflate_WriteLiteral.75
	dw Inflate_WriteLiteral.76, Inflate_WriteLiteral.77, Inflate_WriteLiteral.78, Inflate_WriteLiteral.79
	dw Inflate_WriteLiteral.80, Inflate_WriteLiteral.81, Inflate_WriteLiteral.82, Inflate_WriteLiteral.83
	dw Inflate_WriteLiteral.84, Inflate_WriteLiteral.85, Inflate_WriteLiteral.86, Inflate_WriteLiteral.87
	dw Inflate_WriteLiteral.88, Inflate_WriteLiteral.89, Inflate_WriteLiteral.90, Inflate_WriteLiteral.91
	dw Inflate_WriteLiteral.92, Inflate_WriteLiteral.93, Inflate_WriteLiteral.94, Inflate_WriteLiteral.95
	dw Inflate_WriteLiteral.96, Inflate_WriteLiteral.97, Inflate_WriteLiteral.98, Inflate_WriteLiteral.99
	dw Inflate_WriteLiteral.100, Inflate_WriteLiteral.101, Inflate_WriteLiteral.102, Inflate_WriteLiteral.103
	dw Inflate_WriteLiteral.104, Inflate_WriteLiteral.105, Inflate_WriteLiteral.106, Inflate_WriteLiteral.107
	dw Inflate_WriteLiteral.108, Inflate_WriteLiteral.109, Inflate_WriteLiteral.110, Inflate_WriteLiteral.111
	dw Inflate_WriteLiteral.112, Inflate_WriteLiteral.113, Inflate_WriteLiteral.114, Inflate_WriteLiteral.115
	dw Inflate_WriteLiteral.116, Inflate_WriteLiteral.117, Inflate_WriteLiteral.118, Inflate_WriteLiteral.119
	dw Inflate_WriteLiteral.120, Inflate_WriteLiteral.121, Inflate_WriteLiteral.122, Inflate_WriteLiteral.123
	dw Inflate_WriteLiteral.124, Inflate_WriteLiteral.125, Inflate_WriteLiteral.126, Inflate_WriteLiteral.127
	dw Inflate_WriteLiteral.128, Inflate_WriteLiteral.129, Inflate_WriteLiteral.130, Inflate_WriteLiteral.131
	dw Inflate_WriteLiteral.132, Inflate_WriteLiteral.133, Inflate_WriteLiteral.134, Inflate_WriteLiteral.135
	dw Inflate_WriteLiteral.136, Inflate_WriteLiteral.137, Inflate_WriteLiteral.138, Inflate_WriteLiteral.139
	dw Inflate_WriteLiteral.140, Inflate_WriteLiteral.141, Inflate_WriteLiteral.142, Inflate_WriteLiteral.143
	dw Inflate_WriteLiteral.144, Inflate_WriteLiteral.145, Inflate_WriteLiteral.146, Inflate_WriteLiteral.147
	dw Inflate_WriteLiteral.148, Inflate_WriteLiteral.149, Inflate_WriteLiteral.150, Inflate_WriteLiteral.151
	dw Inflate_WriteLiteral.152, Inflate_WriteLiteral.153, Inflate_WriteLiteral.154, Inflate_WriteLiteral.155
	dw Inflate_WriteLiteral.156, Inflate_WriteLiteral.157, Inflate_WriteLiteral.158, Inflate_WriteLiteral.159
	dw Inflate_WriteLiteral.160, Inflate_WriteLiteral.161, Inflate_WriteLiteral.162, Inflate_WriteLiteral.163
	dw Inflate_WriteLiteral.164, Inflate_WriteLiteral.165, Inflate_WriteLiteral.166, Inflate_WriteLiteral.167
	dw Inflate_WriteLiteral.168, Inflate_WriteLiteral.169, Inflate_WriteLiteral.170, Inflate_WriteLiteral.171
	dw Inflate_WriteLiteral.172, Inflate_WriteLiteral.173, Inflate_WriteLiteral.174, Inflate_WriteLiteral.175
	dw Inflate_WriteLiteral.176, Inflate_WriteLiteral.177, Inflate_WriteLiteral.178, Inflate_WriteLiteral.179
	dw Inflate_WriteLiteral.180, Inflate_WriteLiteral.181, Inflate_WriteLiteral.182, Inflate_WriteLiteral.183
	dw Inflate_WriteLiteral.184, Inflate_WriteLiteral.185, Inflate_WriteLiteral.186, Inflate_WriteLiteral.187
	dw Inflate_WriteLiteral.188, Inflate_WriteLiteral.189, Inflate_WriteLiteral.190, Inflate_WriteLiteral.191
	dw Inflate_WriteLiteral.192, Inflate_WriteLiteral.193, Inflate_WriteLiteral.194, Inflate_WriteLiteral.195
	dw Inflate_WriteLiteral.196, Inflate_WriteLiteral.197, Inflate_WriteLiteral.198, Inflate_WriteLiteral.199
	dw Inflate_WriteLiteral.200, Inflate_WriteLiteral.201, Inflate_WriteLiteral.202, Inflate_WriteLiteral.203
	dw Inflate_WriteLiteral.204, Inflate_WriteLiteral.205, Inflate_WriteLiteral.206, Inflate_WriteLiteral.207
	dw Inflate_WriteLiteral.208, Inflate_WriteLiteral.209, Inflate_WriteLiteral.210, Inflate_WriteLiteral.211
	dw Inflate_WriteLiteral.212, Inflate_WriteLiteral.213, Inflate_WriteLiteral.214, Inflate_WriteLiteral.215
	dw Inflate_WriteLiteral.216, Inflate_WriteLiteral.217, Inflate_WriteLiteral.218, Inflate_WriteLiteral.219
	dw Inflate_WriteLiteral.220, Inflate_WriteLiteral.221, Inflate_WriteLiteral.222, Inflate_WriteLiteral.223
	dw Inflate_WriteLiteral.224, Inflate_WriteLiteral.225, Inflate_WriteLiteral.226, Inflate_WriteLiteral.227
	dw Inflate_WriteLiteral.228, Inflate_WriteLiteral.229, Inflate_WriteLiteral.230, Inflate_WriteLiteral.231
	dw Inflate_WriteLiteral.232, Inflate_WriteLiteral.233, Inflate_WriteLiteral.234, Inflate_WriteLiteral.235
	dw Inflate_WriteLiteral.236, Inflate_WriteLiteral.237, Inflate_WriteLiteral.238, Inflate_WriteLiteral.239
	dw Inflate_WriteLiteral.240, Inflate_WriteLiteral.241, Inflate_WriteLiteral.242, Inflate_WriteLiteral.243
	dw Inflate_WriteLiteral.244, Inflate_WriteLiteral.245, Inflate_WriteLiteral.246, Inflate_WriteLiteral.247
	dw Inflate_WriteLiteral.248, Inflate_WriteLiteral.249, Inflate_WriteLiteral.250, Inflate_WriteLiteral.251
	dw Inflate_WriteLiteral.252, Inflate_WriteLiteral.253, Inflate_WriteLiteral.254, Inflate_WriteLiteral.255
	dw Inflate_EndBlock, Inflate_CopyLength.0, Inflate_CopyLength.1, Inflate_CopyLength.2
	dw Inflate_CopyLength.3, Inflate_CopyLength.4, Inflate_CopyLength.5, Inflate_CopyLength.6
	dw Inflate_CopyLength.7, Inflate_CopyLength.8, Inflate_CopyLength.9, Inflate_CopyLength.10
	dw Inflate_CopyLength.11, Inflate_CopyLength.12, Inflate_CopyLength.13, Inflate_CopyLength.14
	dw Inflate_CopyLength.15, Inflate_CopyLength.16, Inflate_CopyLength.17, Inflate_CopyLength.18
	dw Inflate_CopyLength.19, Inflate_CopyLength.20, Inflate_CopyLength.21, Inflate_CopyLength.22
	dw Inflate_CopyLength.23, Inflate_CopyLength.24, Inflate_CopyLength.25, Inflate_CopyLength.26
	dw Inflate_CopyLength.27, Inflate_CopyLength.28, System_ThrowException, System_ThrowException

Inflate_fixedDistanceCodeLengths:
	db 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5
	db 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5

Inflate_fixedDistanceCodeLengthsCount: equ $ - Inflate_fixedDistanceCodeLengths

Inflate_distanceSymbols:
	dw Inflate_WriteLiteral.0, Inflate_CopyDistance.1, Inflate_CopyDistance.2, Inflate_CopyDistance.3
	dw Inflate_CopyDistance.4, Inflate_CopyDistance.5, Inflate_CopyDistance.6, Inflate_CopyDistance.7
	dw Inflate_CopyDistance.8, Inflate_CopyDistance.9, Inflate_CopyDistance.10, Inflate_CopyDistance.11
	dw Inflate_CopyDistance.12, Inflate_CopyDistance.13, Inflate_CopyDistance.14, Inflate_CopyDistance.15
	dw Inflate_CopyDistance.16, Inflate_CopyDistance.17, Inflate_CopyDistance.18, Inflate_CopyDistance.19
	dw Inflate_CopyDistance.20, Inflate_CopyDistance.21, Inflate_CopyDistance.22, Inflate_CopyDistance.23
	dw Inflate_CopyDistance.24, Inflate_CopyDistance.25, Inflate_CopyDistance.26, Inflate_CopyDistance.27
	dw Inflate_CopyDistance.28, Inflate_CopyDistance.29, System_ThrowException, System_ThrowException

Inflate_invalidBlockTypeError:
	db "Invalid block type.",13,10,0

Inflate_invalidLengthError:
	db "Invalid length.",13,10,0
