;
; Alphabet unit tests
;
AlphabetTest_Test:
	call Alphabet_class.New
	call Alphabet_Construct
	call AlphabetTest_TestCountCodeLenghts
	call AlphabetTest_TestCalculateNextCodes
	call AlphabetTest_TestBuildTree
	call Alphabet_Destruct
	call Alphabet_class.Delete
	ret

; ix = alphabet
AlphabetTest_TestCountCodeLenghts:
	ld bc,Alphabet_fixedCodeLengthsCount
	ld hl,Alphabet_fixedCodeLengths
	call Alphabet_CountCodeLengths
	ld e,ixl
	ld d,ixh
	ld hl,Alphabet.codeLengthCounts
	add hl,de
	ex de,hl
	ld hl,AlphabetTest_expectedCodeLengthCounts
	ld bc,Alphabet_MAX_CODELENGTH + 1
	call AlphabetTest_AssertArrayEquals
	ret

AlphabetTest_expectedCodeLengthCounts:
	db 0, 0, 0, 0, 0, 0, 0, 24, 152, 112, 0, 0, 0, 0, 0, 0, 0

; ix = alphabet
AlphabetTest_TestCalculateNextCodes:
	call Alphabet_CalculateNextCodes
	ld e,ixl
	ld d,ixh
	ld hl,Alphabet.nextCodes
	add hl,de
	ex de,hl
	ld hl,AlphabetTest_expectedNextCodes
	ld bc,Alphabet_MAX_CODELENGTH * 2
	call AlphabetTest_AssertArrayEquals
	ret

AlphabetTest_expectedNextCodes:
	dw 0, 0, 0, 0, 0, 0, 0, 48, 400, 1024, 2048, 4096, 8192, 16384, 32768, 0

; ix = alphabet
AlphabetTest_TestBuildTree:
	ld bc,Alphabet_fixedCodeLengthsCount
	ld de,Alphabet_fixedCodeLengths
	ld hl,AlphabetTest_literalLengthSymbols
	call Alphabet_BuildTree
	ld de,00E2H
	jp ix
	cp 23
	call nz,System_ThrowException
	ld a,b
	cp 8
	call nz,System_ThrowException
	ld de,01FBH
	jp ix
	cp 191
	call nz,System_ThrowException
	ld a,b
	cp 9
	call nz,System_ThrowException
	ret

; hl = array A
; de = array B
; bc = nr of bytes to compare
AlphabetTest_AssertArrayEquals:
	ld a,(de)
	inc de
	cpi
	call nz,System_ThrowException
	jp pe,AlphabetTest_AssertArrayEquals
	ret

;
AlphabetTest_literalLengthSymbols:
	dw AlphabetTest_ReturnLiteral.0, AlphabetTest_ReturnLiteral.1, AlphabetTest_ReturnLiteral.2, AlphabetTest_ReturnLiteral.3
	dw AlphabetTest_ReturnLiteral.4, AlphabetTest_ReturnLiteral.5, AlphabetTest_ReturnLiteral.6, AlphabetTest_ReturnLiteral.7
	dw AlphabetTest_ReturnLiteral.8, AlphabetTest_ReturnLiteral.9, AlphabetTest_ReturnLiteral.10, AlphabetTest_ReturnLiteral.11
	dw AlphabetTest_ReturnLiteral.12, AlphabetTest_ReturnLiteral.13, AlphabetTest_ReturnLiteral.14, AlphabetTest_ReturnLiteral.15
	dw AlphabetTest_ReturnLiteral.16, AlphabetTest_ReturnLiteral.17, AlphabetTest_ReturnLiteral.18, AlphabetTest_ReturnLiteral.19
	dw AlphabetTest_ReturnLiteral.20, AlphabetTest_ReturnLiteral.21, AlphabetTest_ReturnLiteral.22, AlphabetTest_ReturnLiteral.23
	dw AlphabetTest_ReturnLiteral.24, AlphabetTest_ReturnLiteral.25, AlphabetTest_ReturnLiteral.26, AlphabetTest_ReturnLiteral.27
	dw AlphabetTest_ReturnLiteral.28, AlphabetTest_ReturnLiteral.29, AlphabetTest_ReturnLiteral.30, AlphabetTest_ReturnLiteral.31
	dw AlphabetTest_ReturnLiteral.32, AlphabetTest_ReturnLiteral.33, AlphabetTest_ReturnLiteral.34, AlphabetTest_ReturnLiteral.35
	dw AlphabetTest_ReturnLiteral.36, AlphabetTest_ReturnLiteral.37, AlphabetTest_ReturnLiteral.38, AlphabetTest_ReturnLiteral.39
	dw AlphabetTest_ReturnLiteral.40, AlphabetTest_ReturnLiteral.41, AlphabetTest_ReturnLiteral.42, AlphabetTest_ReturnLiteral.43
	dw AlphabetTest_ReturnLiteral.44, AlphabetTest_ReturnLiteral.45, AlphabetTest_ReturnLiteral.46, AlphabetTest_ReturnLiteral.47
	dw AlphabetTest_ReturnLiteral.48, AlphabetTest_ReturnLiteral.49, AlphabetTest_ReturnLiteral.50, AlphabetTest_ReturnLiteral.51
	dw AlphabetTest_ReturnLiteral.52, AlphabetTest_ReturnLiteral.53, AlphabetTest_ReturnLiteral.54, AlphabetTest_ReturnLiteral.55
	dw AlphabetTest_ReturnLiteral.56, AlphabetTest_ReturnLiteral.57, AlphabetTest_ReturnLiteral.58, AlphabetTest_ReturnLiteral.59
	dw AlphabetTest_ReturnLiteral.60, AlphabetTest_ReturnLiteral.61, AlphabetTest_ReturnLiteral.62, AlphabetTest_ReturnLiteral.63
	dw AlphabetTest_ReturnLiteral.64, AlphabetTest_ReturnLiteral.65, AlphabetTest_ReturnLiteral.66, AlphabetTest_ReturnLiteral.67
	dw AlphabetTest_ReturnLiteral.68, AlphabetTest_ReturnLiteral.69, AlphabetTest_ReturnLiteral.70, AlphabetTest_ReturnLiteral.71
	dw AlphabetTest_ReturnLiteral.72, AlphabetTest_ReturnLiteral.73, AlphabetTest_ReturnLiteral.74, AlphabetTest_ReturnLiteral.75
	dw AlphabetTest_ReturnLiteral.76, AlphabetTest_ReturnLiteral.77, AlphabetTest_ReturnLiteral.78, AlphabetTest_ReturnLiteral.79
	dw AlphabetTest_ReturnLiteral.80, AlphabetTest_ReturnLiteral.81, AlphabetTest_ReturnLiteral.82, AlphabetTest_ReturnLiteral.83
	dw AlphabetTest_ReturnLiteral.84, AlphabetTest_ReturnLiteral.85, AlphabetTest_ReturnLiteral.86, AlphabetTest_ReturnLiteral.87
	dw AlphabetTest_ReturnLiteral.88, AlphabetTest_ReturnLiteral.89, AlphabetTest_ReturnLiteral.90, AlphabetTest_ReturnLiteral.91
	dw AlphabetTest_ReturnLiteral.92, AlphabetTest_ReturnLiteral.93, AlphabetTest_ReturnLiteral.94, AlphabetTest_ReturnLiteral.95
	dw AlphabetTest_ReturnLiteral.96, AlphabetTest_ReturnLiteral.97, AlphabetTest_ReturnLiteral.98, AlphabetTest_ReturnLiteral.99
	dw AlphabetTest_ReturnLiteral.100, AlphabetTest_ReturnLiteral.101, AlphabetTest_ReturnLiteral.102, AlphabetTest_ReturnLiteral.103
	dw AlphabetTest_ReturnLiteral.104, AlphabetTest_ReturnLiteral.105, AlphabetTest_ReturnLiteral.106, AlphabetTest_ReturnLiteral.107
	dw AlphabetTest_ReturnLiteral.108, AlphabetTest_ReturnLiteral.109, AlphabetTest_ReturnLiteral.110, AlphabetTest_ReturnLiteral.111
	dw AlphabetTest_ReturnLiteral.112, AlphabetTest_ReturnLiteral.113, AlphabetTest_ReturnLiteral.114, AlphabetTest_ReturnLiteral.115
	dw AlphabetTest_ReturnLiteral.116, AlphabetTest_ReturnLiteral.117, AlphabetTest_ReturnLiteral.118, AlphabetTest_ReturnLiteral.119
	dw AlphabetTest_ReturnLiteral.120, AlphabetTest_ReturnLiteral.121, AlphabetTest_ReturnLiteral.122, AlphabetTest_ReturnLiteral.123
	dw AlphabetTest_ReturnLiteral.124, AlphabetTest_ReturnLiteral.125, AlphabetTest_ReturnLiteral.126, AlphabetTest_ReturnLiteral.127
	dw AlphabetTest_ReturnLiteral.128, AlphabetTest_ReturnLiteral.129, AlphabetTest_ReturnLiteral.130, AlphabetTest_ReturnLiteral.131
	dw AlphabetTest_ReturnLiteral.132, AlphabetTest_ReturnLiteral.133, AlphabetTest_ReturnLiteral.134, AlphabetTest_ReturnLiteral.135
	dw AlphabetTest_ReturnLiteral.136, AlphabetTest_ReturnLiteral.137, AlphabetTest_ReturnLiteral.138, AlphabetTest_ReturnLiteral.139
	dw AlphabetTest_ReturnLiteral.140, AlphabetTest_ReturnLiteral.141, AlphabetTest_ReturnLiteral.142, AlphabetTest_ReturnLiteral.143
	dw AlphabetTest_ReturnLiteral.144, AlphabetTest_ReturnLiteral.145, AlphabetTest_ReturnLiteral.146, AlphabetTest_ReturnLiteral.147
	dw AlphabetTest_ReturnLiteral.148, AlphabetTest_ReturnLiteral.149, AlphabetTest_ReturnLiteral.150, AlphabetTest_ReturnLiteral.151
	dw AlphabetTest_ReturnLiteral.152, AlphabetTest_ReturnLiteral.153, AlphabetTest_ReturnLiteral.154, AlphabetTest_ReturnLiteral.155
	dw AlphabetTest_ReturnLiteral.156, AlphabetTest_ReturnLiteral.157, AlphabetTest_ReturnLiteral.158, AlphabetTest_ReturnLiteral.159
	dw AlphabetTest_ReturnLiteral.160, AlphabetTest_ReturnLiteral.161, AlphabetTest_ReturnLiteral.162, AlphabetTest_ReturnLiteral.163
	dw AlphabetTest_ReturnLiteral.164, AlphabetTest_ReturnLiteral.165, AlphabetTest_ReturnLiteral.166, AlphabetTest_ReturnLiteral.167
	dw AlphabetTest_ReturnLiteral.168, AlphabetTest_ReturnLiteral.169, AlphabetTest_ReturnLiteral.170, AlphabetTest_ReturnLiteral.171
	dw AlphabetTest_ReturnLiteral.172, AlphabetTest_ReturnLiteral.173, AlphabetTest_ReturnLiteral.174, AlphabetTest_ReturnLiteral.175
	dw AlphabetTest_ReturnLiteral.176, AlphabetTest_ReturnLiteral.177, AlphabetTest_ReturnLiteral.178, AlphabetTest_ReturnLiteral.179
	dw AlphabetTest_ReturnLiteral.180, AlphabetTest_ReturnLiteral.181, AlphabetTest_ReturnLiteral.182, AlphabetTest_ReturnLiteral.183
	dw AlphabetTest_ReturnLiteral.184, AlphabetTest_ReturnLiteral.185, AlphabetTest_ReturnLiteral.186, AlphabetTest_ReturnLiteral.187
	dw AlphabetTest_ReturnLiteral.188, AlphabetTest_ReturnLiteral.189, AlphabetTest_ReturnLiteral.190, AlphabetTest_ReturnLiteral.191
	dw AlphabetTest_ReturnLiteral.192, AlphabetTest_ReturnLiteral.193, AlphabetTest_ReturnLiteral.194, AlphabetTest_ReturnLiteral.195
	dw AlphabetTest_ReturnLiteral.196, AlphabetTest_ReturnLiteral.197, AlphabetTest_ReturnLiteral.198, AlphabetTest_ReturnLiteral.199
	dw AlphabetTest_ReturnLiteral.200, AlphabetTest_ReturnLiteral.201, AlphabetTest_ReturnLiteral.202, AlphabetTest_ReturnLiteral.203
	dw AlphabetTest_ReturnLiteral.204, AlphabetTest_ReturnLiteral.205, AlphabetTest_ReturnLiteral.206, AlphabetTest_ReturnLiteral.207
	dw AlphabetTest_ReturnLiteral.208, AlphabetTest_ReturnLiteral.209, AlphabetTest_ReturnLiteral.210, AlphabetTest_ReturnLiteral.211
	dw AlphabetTest_ReturnLiteral.212, AlphabetTest_ReturnLiteral.213, AlphabetTest_ReturnLiteral.214, AlphabetTest_ReturnLiteral.215
	dw AlphabetTest_ReturnLiteral.216, AlphabetTest_ReturnLiteral.217, AlphabetTest_ReturnLiteral.218, AlphabetTest_ReturnLiteral.219
	dw AlphabetTest_ReturnLiteral.220, AlphabetTest_ReturnLiteral.221, AlphabetTest_ReturnLiteral.222, AlphabetTest_ReturnLiteral.223
	dw AlphabetTest_ReturnLiteral.224, AlphabetTest_ReturnLiteral.225, AlphabetTest_ReturnLiteral.226, AlphabetTest_ReturnLiteral.227
	dw AlphabetTest_ReturnLiteral.228, AlphabetTest_ReturnLiteral.229, AlphabetTest_ReturnLiteral.230, AlphabetTest_ReturnLiteral.231
	dw AlphabetTest_ReturnLiteral.232, AlphabetTest_ReturnLiteral.233, AlphabetTest_ReturnLiteral.234, AlphabetTest_ReturnLiteral.235
	dw AlphabetTest_ReturnLiteral.236, AlphabetTest_ReturnLiteral.237, AlphabetTest_ReturnLiteral.238, AlphabetTest_ReturnLiteral.239
	dw AlphabetTest_ReturnLiteral.240, AlphabetTest_ReturnLiteral.241, AlphabetTest_ReturnLiteral.242, AlphabetTest_ReturnLiteral.243
	dw AlphabetTest_ReturnLiteral.244, AlphabetTest_ReturnLiteral.245, AlphabetTest_ReturnLiteral.246, AlphabetTest_ReturnLiteral.247
	dw AlphabetTest_ReturnLiteral.248, AlphabetTest_ReturnLiteral.249, AlphabetTest_ReturnLiteral.250, AlphabetTest_ReturnLiteral.251
	dw AlphabetTest_ReturnLiteral.252, AlphabetTest_ReturnLiteral.253, AlphabetTest_ReturnLiteral.254, AlphabetTest_ReturnLiteral.255
	dw System_ThrowException, System_ThrowException, System_ThrowException, System_ThrowException
	dw System_ThrowException, System_ThrowException, System_ThrowException, System_ThrowException
	dw System_ThrowException, System_ThrowException, System_ThrowException, System_ThrowException
	dw System_ThrowException, System_ThrowException, System_ThrowException, System_ThrowException
	dw System_ThrowException, System_ThrowException, System_ThrowException, System_ThrowException
	dw System_ThrowException, System_ThrowException, System_ThrowException, System_ThrowException
	dw System_ThrowException, System_ThrowException, System_ThrowException, System_ThrowException
	dw System_ThrowException, System_ThrowException, System_ThrowException, System_ThrowException

; ix = this
AlphabetTest_ReturnLiteral: REPT 256, ?value
	ld a,?value
	ret
	ENDM
