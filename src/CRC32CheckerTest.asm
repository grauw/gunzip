;
; CRC32 checker unit tests
;
CRC32CheckerTest_Test:
	call CRC32CheckerTest_TestCRC32
	ret

CRC32CheckerTest_TestCRC32: PROC
	ld hl,WRITEBUFFER
	ld bc,256
	call NullWriter_class.New
	call NullWriter_Construct
	push ix
	pop iy

	call CRC32Checker_class.New
	call CRC32Checker_Construct

	call CRC32Checker_GetCRC32
	ld a,e
	and d
	and c
	and b
	inc a
	call nz,System_ThrowException

	ld b,58
Loop1:
	ld a,b
	call Writer_Write_IY
	djnz Loop1
	call Writer_FinishBlock_IY
	call CRC32Checker_GetCRC32
	ld hl,07364H
	scf
	adc hl,de
	call nz,System_ThrowException
	ld hl,0DAA8H
	scf
	adc hl,bc
	call nz,System_ThrowException

	ld b,200
Loop2:
	ld a,b
	call Writer_Write_IY
	djnz Loop2
	call Writer_FinishBlock_IY
	call CRC32Checker_GetCRC32
	ld hl,04E96H
	scf
	adc hl,de
	call nz,System_ThrowException
	ld hl,02DA9H
	scf
	adc hl,bc
	call nz,System_ThrowException

	call CRC32Checker_Destruct
	call CRC32Checker_class.Delete

	push iy
	pop ix
	call NullWriter_Destruct
	call NullWriter_class.Delete
	ret
	ENDP
