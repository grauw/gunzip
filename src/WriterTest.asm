;
; Writer unit tests
;
WriterTest_Test:
	call WriterTest_TestCount
	call WriterTest_TestCRC32
	ret

WriterTest_TestCount: PROC
	ld hl,OBUFFER
	ld bc,256
	call NullWriter_class.New
	call NullWriter_Construct

	call Writer_GetCount
	ld a,l
	or h
	or e
	or d
	call nz,System_ThrowException

	ld b,58
Loop1:
	call Writer_Write
	djnz Loop1
	call Writer_GetCount
	ld bc,58
	and a
	sbc hl,bc
	call nz,System_ThrowException
	ld a,e
	or d
	call nz,System_ThrowException

	ld b,200
Loop2:
	call Writer_Write
	djnz Loop2
	call Writer_GetCount
	ld bc,258
	and a
	sbc hl,bc
	call nz,System_ThrowException
	ld a,e
	or d
	call nz,System_ThrowException

	call NullWriter_Destruct
	call NullWriter_class.Delete
	ret
	ENDP

WriterTest_TestCRC32: PROC
	ld hl,OBUFFER
	ld bc,256
	call NullWriter_class.New
	call NullWriter_Construct

	call Writer_GetCRC32
	ld a,l
	and h
	and e
	and d
	inc a
	call nz,System_ThrowException

	ld b,58
Loop1:
	ld a,b
	call Writer_Write
	djnz Loop1
	call Writer_GetCRC32
	ld a,l
	cpl
	cp 064H
	call nz,System_ThrowException
	ld a,h
	cpl
	cp 073H
	call nz,System_ThrowException
	ld a,e
	cpl
	cp 0A8H
	call nz,System_ThrowException
	ld a,d
	cpl
	cp 0DAH
	call nz,System_ThrowException

	ld b,200
Loop2:
	ld a,b
	call Writer_Write
	djnz Loop2
	call Writer_GetCRC32
	ld a,l
	cpl
	cp 096H
	call nz,System_ThrowException
	ld a,h
	cpl
	cp 04EH
	call nz,System_ThrowException
	ld a,e
	cpl
	cp 0A9H
	call nz,System_ThrowException
	ld a,d
	cpl
	cp 02DH
	call nz,System_ThrowException

	call NullWriter_Destruct
	call NullWriter_class.Delete
	ret
	ENDP
