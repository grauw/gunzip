;
; Alphabet unit tests
;
AlphabetTest_Test:
	call AlphabetTest_TestCodeBuilding
	call AlphabetTest_TestCompleteCodes
	call AlphabetTest_TestTreeBuilding
	ret

AlphabetTest_TestCodeBuilding:
	ld bc,HuffmanCodes_fixedLiteralLengthCodeLengthsCount
	ld de,HuffmanCodes_fixedLiteralLengthCodeLengths
	ld hl,Inflate_literalLengthSymbols
	call AlphabetTest_AssertConstructSuccess
	ret

AlphabetTest_expectedCodeLengthCounts:
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 24, 0, 152, 0
	db 112, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

AlphabetTest_TestCompleteCodes:
	ld bc,1
	ld de,AlphabetTest_testCodeLengths0
	ld hl,AlphabetTest_testSymbols
	call AlphabetTest_AssertConstructSuccess
	ld bc,1
	ld de,AlphabetTest_testCodeLengths11
	ld hl,AlphabetTest_testSymbols
	call AlphabetTest_AssertConstructSuccess
	ld bc,2
	ld de,AlphabetTest_testCodeLengths11
	ld hl,AlphabetTest_testSymbols
	call AlphabetTest_AssertConstructSuccess
	ld bc,3
	ld de,AlphabetTest_testCodeLengths122
	ld hl,AlphabetTest_testSymbols
	call AlphabetTest_AssertConstructSuccess
	ld bc,4
	ld de,AlphabetTest_testCodeLengths2222
	ld hl,AlphabetTest_testSymbols
	call AlphabetTest_AssertConstructSuccess
	ret

AlphabetTest_testCodeLengths0:
	db 0

AlphabetTest_testCodeLengths11:
	db 1, 1

AlphabetTest_testCodeLengths122:
	db 1, 2, 2

AlphabetTest_testCodeLengths2222:
	db 2, 2, 2, 2

AlphabetTest_TestTreeBuilding: PROC
	ld bc,AlphabetTest_testCodeLengthsCount
	ld de,AlphabetTest_testCodeLengths
	ld hl,AlphabetTest_testSymbols
	ld ix,AlphabetTest_alphabet
	call Alphabet_Construct

	ld hl,AlphabetTest_testCodes
	ld de,READBUFFER
	ld bc,AlphabetTest_testCodes_size
	ldir
	ld hl,READBUFFER
	ld bc,READBUFFER_SIZE
	ld de,Reader_DefaultFiller
	ld ix,AlphabetTest_reader
	call Reader_Construct

	ld iy,AlphabetTest_reader
	call Reader_PrepareReadBitInline_IY
	ld d,7
	ld hl,AlphabetTest_expectedSymbols
	ld ix,AlphabetTest_alphabet
Loop:
	push hl
	call Alphabet_Process
	pop hl
	cp (hl)
	call nz,System_ThrowException
	inc hl
	dec d
	jr nz,Loop
	call Reader_FinishReadBitInline_IY

	ld ix,AlphabetTest_reader
	call Reader_Destruct

	ld ix,AlphabetTest_alphabet
	call Alphabet_Destruct
	ret
	ENDP

AlphabetTest_alphabet:
	Alphabet

AlphabetTest_reader:
	Reader

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

AlphabetTest_ReturnLiteral: REPT 7, ?value
	ld a,?value
	ret
	ENDM

AlphabetTest_testCodes:
	db 11010010B, 11011001B, 1111011B
AlphabetTest_testCodes_size: equ $ - AlphabetTest_testCodes

AlphabetTest_expectedSymbols:
	db 3, 1, 4, 0, 2, 5, 6

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

AlphabetTest_AssertConstructSuccess:
	ld ix,AlphabetTest_alphabet
	call Alphabet_Construct
	call Alphabet_Destruct
	ret
