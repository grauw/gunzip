;
; Writer unit tests
;
WriterTest_Test:
	call WriterTest_TestCount
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
