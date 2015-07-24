;
; Huffman alphabet
;
Alphabet_MAX_CODELENGTH: equ 16

Alphabet: MACRO
	; de = next 16 bits
	; ix = inflate object
	; b <- bits consumed
	; de <- next 16-b bits
	Process:
		jp 0
	root: equ $ - 2
	codeLengthCounts:
		ds Alphabet_MAX_CODELENGTH + 1, 0  ; allocate on stack?
	nextCodes:
		ds Alphabet_MAX_CODELENGTH * 2, 0
	_size:
	ENDM

Alphabet_class: Class Alphabet, Alphabet_template, Heap_main
Alphabet_template: Alphabet

; ix = this
; ix <- this
; de <- this
Alphabet_Construct:
	push ix
	call Branch_class.New
	call Branch_Construct
	pop ix
	ld (ix + Alphabet.root),e
	ld (ix + Alphabet.root + 1),d
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
Alphabet_Destruct:
	push ix
	call Alphabet_GetRoot
	call Branch_Destruct
	call Branch_class.Delete
	pop ix
	ret

; ix = this
; ix <- root branch
; de <- root branch
Alphabet_GetRoot:
	ld e,(ix + Alphabet.root)
	ld d,(ix + Alphabet.root + 1)
	ld ixl,e
	ld ixh,d
	ret

; de = next 16 bits
; ix = this
; b <- bits consumed
; de <- next 16-b bits
; Modifies: f, b, de
Alphabet_Process:
	ld b,0
	jp ix

; bc = code length table length
; hl = code length table
; ix = this
Alphabet_SetCodeLengths:
	push bc
	push hl
	call Alphabet_CountCodeLengths
	call Alphabet_CalculateNextCodes
	pop de
	pop bc
	ld hl,Alphabet_literalLengthSymbols
	call Alphabet_BuildTree
	ret

; bc = code length table length
; hl = code length table
; ix = this
Alphabet_CountCodeLengths:
	ld a,c  ; convert 16-bit counter bc to two 8-bit counters in b and c
	dec bc
	inc b
	ld c,b
	ld b,a
Loop:
	ld a,(hl)
	inc hl
	call Alphabet_CountCodeLength
	djnz Loop
	dec c
	jr nz,Loop
	ret

; a = code length
; ix = this
; Modifies: af, de
Alphabet_CountCodeLength:
	cp Alphabet_MAX_CODELENGTH + 1
	call nc,System_ThrowException
	push ix
	ld e,a
	ld d,0
	add ix,de
	inc (ix + Alphabet.codeLengthCounts)
	call z,System_ThrowException
	pop ix
	ret

; ix = this
Alphabet_CalculateNextCodes: PROC
	push ix
	push ix
	pop iy
	ld hl,0  ; code
	ld b,Alphabet_MAX_CODELENGTH - 1
Loop:
	ld (iy + Alphabet.nextCodes),l
	ld (iy + Alphabet.nextCodes + 1),h
	inc iy
	inc iy
	ld e,(ix + Alphabet.codeLengthCounts + 1)
	ld d,0
	inc ix
	add hl,de
	add hl,hl
	djnz Loop
	ld (iy + Alphabet.nextCodes),l
	ld (iy + Alphabet.nextCodes + 1),h
	pop ix
	ret
	ENDP

; bc = code length table length
; de = code length table
; hl = symbol handler table
; ix = this
Alphabet_BuildTree: PROC
	ld a,c  ; convert 16-bit counter bc to two 8-bit counters in b and c
	dec bc
	inc b
	ld c,b
	ld b,a
Loop:
	push bc
	ld a,(de)
	inc de
	push de
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	push hl
	and a
	call nz,Alphabet_AddTreeNode
	pop hl
	pop de
	pop bc
	djnz Loop
	dec c
	jr nz,Loop
	ret
	ENDP

; a = code length (> 0)
; de = symbol callback
Alphabet_AddTreeNode: PROC
	ld iyl,e
	ld iyh,d
	ld b,a
	add a,a
	ld e,a
	ld d,0
	push ix
	add ix,de
	ld l,(ix + Alphabet.nextCodes - 2)
	ld h,(ix + Alphabet.nextCodes - 1)
	inc hl
	ld (ix + Alphabet.nextCodes - 2),l
	ld (ix + Alphabet.nextCodes - 1),h
	dec hl
	pop ix
	ld a,16
	sub b
	jr z,NoPreShift
PreShiftLoop:
	add hl,hl
	dec a
	jp nz,PreShiftLoop
NoPreShift:
	push ix
	call Alphabet_GetRoot
	call Branch_Build
	pop ix
	ret
	ENDP

;
Alphabet_fixedCodeLengths:
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8  ; 0-144: 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9  ; 144-256: 9
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 7, 7, 7, 7, 7, 7, 7, 7  ; 256-280: 7
	db 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8  ; 280-288: 8

Alphabet_fixedCodeLengthsCount: equ $ - Alphabet_fixedCodeLengths

;
Alphabet_literalLengthSymbols:
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
	dw Inflate_WriteLiteral.0, Inflate_WriteLiteral.0, Inflate_WriteLiteral.0, Inflate_WriteLiteral.0
	dw Inflate_WriteLiteral.0, Inflate_WriteLiteral.0, Inflate_WriteLiteral.0, Inflate_WriteLiteral.0
	dw Inflate_WriteLiteral.0, Inflate_WriteLiteral.0, Inflate_WriteLiteral.0, Inflate_WriteLiteral.0
	dw Inflate_WriteLiteral.0, Inflate_WriteLiteral.0, Inflate_WriteLiteral.0, Inflate_WriteLiteral.0
	dw Inflate_WriteLiteral.0, Inflate_WriteLiteral.0, Inflate_WriteLiteral.0, Inflate_WriteLiteral.0
	dw Inflate_WriteLiteral.0, Inflate_WriteLiteral.0, Inflate_WriteLiteral.0, Inflate_WriteLiteral.0
	dw Inflate_WriteLiteral.0, Inflate_WriteLiteral.0, Inflate_WriteLiteral.0, Inflate_WriteLiteral.0
	dw Inflate_WriteLiteral.0, Inflate_WriteLiteral.0, Inflate_WriteLiteral.0, Inflate_WriteLiteral.0
