;
; Alphabet unit tests
;
AlphabetTest_Test:
	call Alphabet_class.New
	call AlphabetTest_TestCountBitLenghts
	call AlphabetTest_TestGetMaximumBits
	call AlphabetTest_TestCalculateNextCodes
	call Alphabet_class.Destroy
	ret

; ix = alphabet
AlphabetTest_TestCountBitLenghts:
	ld hl,Alphabet_fixedCodeLengths
	call Alphabet_CountBitLengths
	ld e,ixl
	ld d,ixh
	ld hl,Alphabet.bitCounts
	add hl,de
	ex de,hl
	ld hl,AlphabetTest_expectedBitCounts
	ld bc,Alphabet_MAX_BITLENGTH + 1
	call AlphabetTest_AssertArrayEquals
	ret

AlphabetTest_expectedBitCounts:
	db 0, 0, 0, 0, 0, 0, 0, 24, 152, 112, 0, 0, 0, 0, 0, 0, 0

; ix = alphabet
AlphabetTest_TestGetMaximumBits:
	call Alphabet_GetMaximumBits
	ld a,9
	cp b
	call nz,System_ThrowException
	ret

; ix = alphabet
AlphabetTest_TestCalculateNextCodes:
	call Alphabet_CalculateNextCodes
	ld e,ixl
	ld d,ixh
	ld hl,Alphabet.nextCodes
	add hl,de
	ex de,hl
	ld hl,AlphabetTest_expectedNextCodes
	ld bc,Alphabet_MAX_BITLENGTH * 2
	call AlphabetTest_AssertArrayEquals
	ret

AlphabetTest_expectedNextCodes:
	dw 0, 0, 0, 0, 0, 0, 0, 48, 400, 0, 0, 0, 0, 0, 0, 0

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
