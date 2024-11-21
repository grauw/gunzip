;
; CRC32 checker unit tests
;
CRC32CheckerTest_Test:
	IF GZIP_CRC32
	call CRC32CheckerTest_TestCRC32
	ENDIF
	ret

	IF GZIP_CRC32

CRC32CheckerTest_TestCRC32: PROC
	ld hl,WRITEBUFFER
	ld bc,256
	ld ix,CRC32CheckerTest_nullWriter
	call NullWriter_Construct

	ld ix,CRC32CheckerTest_crc32Checker
	call CRC32Checker_Construct

	ld de,0
	ld bc,0
	ld ix,CRC32CheckerTest_crc32Checker
	call CRC32Checker_VerifyCRC32
	call nz,System_ThrowException

	ld b,58
	ld ix,CRC32CheckerTest_nullWriter
Loop1:
	ld a,b
	call Writer_Write
	djnz Loop1
	call Writer_FinishBlock
	ld de,07364H
	ld bc,0DAA8H
	ld ix,CRC32CheckerTest_crc32Checker
	call CRC32Checker_VerifyCRC32
	call nz,System_ThrowException

	ld b,200
	ld ix,CRC32CheckerTest_nullWriter
Loop2:
	ld a,b
	call Writer_Write
	djnz Loop2
	call Writer_FinishBlock
	ld de,04E96H
	ld bc,02DA9H
	ld ix,CRC32CheckerTest_crc32Checker
	call CRC32Checker_VerifyCRC32
	call nz,System_ThrowException

	ld ix,CRC32CheckerTest_nullWriter
	call NullWriter_Destruct
	ret
	ENDP

;
CRC32CheckerTest_crc32Checker:
	CRC32Checker

CRC32CheckerTest_nullWriter:
	NullWriter

	ENDIF
