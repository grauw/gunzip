;
; Alphabet unit tests
;
AlphabetTest_Test:
	call AlphabetTest_TestCodeBuilding
	call AlphabetTest_TestTreeBuilding
	ret

; ix = alphabet
AlphabetTest_TestCodeBuilding:
	call Alphabet_class.New
	call Alphabet_Construct

	ld bc,Inflate_fixedLiteralLengthCodeLengthsCount
	ld hl,Inflate_fixedLiteralLengthCodeLengths
	call Alphabet_CountCodeLengths
	ld e,ixl
	ld d,ixh
	ld hl,Alphabet.codeLengthCounts
	add hl,de
	ex de,hl
	ld hl,AlphabetTest_expectedCodeLengthCounts
	ld bc,Alphabet_MAX_CODELENGTH + 1
	call AlphabetTest_AssertArrayEquals

	call Alphabet_CalculateNextCodes
	ld e,ixl
	ld d,ixh
	ld hl,Alphabet.nextCodes
	add hl,de
	ex de,hl
	ld hl,AlphabetTest_expectedNextCodes
	ld bc,Alphabet_MAX_CODELENGTH * 2
	call AlphabetTest_AssertArrayEquals

	call Alphabet_Destruct
	call Alphabet_class.Delete
	ret

AlphabetTest_expectedCodeLengthCounts:
	db 0, 0, 0, 0, 0, 0, 0, 24, 152, 112, 0, 0, 0, 0, 0, 0, 0

AlphabetTest_expectedNextCodes:
	dw 0, 0, 0, 0, 0, 0, 0, 48, 400, 1024, 2048, 4096, 8192, 16384, 32768, 0

; ix = alphabet
AlphabetTest_TestTreeBuilding:
	call Alphabet_class.New
	call Alphabet_Construct

	ld bc,AlphabetTest_testCodeLengthsCount
	ld de,AlphabetTest_testCodeLengths
	ld hl,AlphabetTest_testSymbols
	call Alphabet_Initialize
	ld de,0B
	call Alphabet_Process
	cp 3
	call nz,System_ThrowException
	ld a,b
	cp 1
	call nz,System_ThrowException
	ld de,001B
	call Alphabet_Process
	cp 1
	call nz,System_ThrowException
	ld a,b
	cp 3
	call nz,System_ThrowException
	ld de,101B
	call Alphabet_Process
	cp 4
	call nz,System_ThrowException
	ld a,b
	cp 3
	call nz,System_ThrowException
	ld de,0011B
	call Alphabet_Process
	cp 0
	call nz,System_ThrowException
	ld a,b
	cp 4
	call nz,System_ThrowException
	ld de,1011B
	call Alphabet_Process
	cp 2
	call nz,System_ThrowException
	ld a,b
	cp 4
	call nz,System_ThrowException
	ld de,0111B
	call Alphabet_Process
	cp 5
	call nz,System_ThrowException
	ld a,b
	cp 4
	call nz,System_ThrowException
	ld de,1111B
	call Alphabet_Process
	cp 6
	call nz,System_ThrowException
	ld a,b
	cp 4
	call nz,System_ThrowException

	call Alphabet_Destruct
	call Alphabet_class.Delete
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
AlphabetTest_testCodeLengths:
	db 4, 3, 4, 1, 3, 4, 4

AlphabetTest_testCodeLengthsCount: equ $ - AlphabetTest_testCodeLengths

AlphabetTest_testSymbols:
	dw AlphabetTest_ReturnLiteral.0
	dw AlphabetTest_ReturnLiteral.1
	dw AlphabetTest_ReturnLiteral.2
	dw AlphabetTest_ReturnLiteral.3
	dw AlphabetTest_ReturnLiteral.4
	dw AlphabetTest_ReturnLiteral.5
	dw AlphabetTest_ReturnLiteral.6

; ix = this
AlphabetTest_ReturnLiteral: REPT 7, ?value
	ld a,?value
	ret
	ENDM
