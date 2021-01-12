;
; Top-level application program class
;
Application: MACRO
	outputSize:
		dd 0
	cli:
		CLI
	fileReader:
		FileReader
	fileWriter:
		FileWriter
	nullWriter:
		NullWriter
	gzipArchive:
		GzipArchive
	_size:
	ENDM

;
Application_Main:
	call Application_CheckStack

	ld ix,Heap_main
	call Heap_Construct
	ld bc,HEAP_SIZE
	ld de,HEAP
	call Heap_Free

	call WriterTest_Test
	call CRC32CheckerTest_Test
	call AlphabetTest_Test

	ld ix,Application_instance
	call Application_Construct
	push ix
	ld hl,Application_EnterMainLoop
	call System_TryCall
	pop ix
	call Application_Destruct
	call System_Rethrow
	ret

; ix = this
; ix <- this
; de <- this
Application_Construct:
	push ix
	call Application_GetCLI
	call CLI_Construct
	pop ix
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
Application_Destruct:
	push ix
	call Application_GetCLI
	call CLI_Destruct
	pop ix
	ret

; ix = this
; ix <- command-line interface
; Modifies: f
Application_GetCLI:
	push de
	ld de,Application.cli
	add ix,de
	pop de
	ret

; ix = this
; ix <- file reader
; Modifies: f
Application_GetFileReader:
	push de
	ld de,Application.fileReader
	add ix,de
	pop de
	ret

; ix = this
; ix <- file writer
; Modifies: f
Application_GetFileWriter:
	push de
	ld de,Application.fileWriter
	add ix,de
	pop de
	ret

; ix = this
; ix <- null writer
; Modifies: f
Application_GetNullWriter:
	push de
	ld de,Application.nullWriter
	add ix,de
	pop de
	ret

; ix = this
; ix <- gzip archive
; Modifies: f
Application_GetGzipArchive:
	push de
	ld de,Application.gzipArchive
	add ix,de
	pop de
	ret

; ix = this
Application_EnterMainLoop:
	call Application_ParseCLI
	call Application_PrintWelcome
	call Application_Inflate
	ret

; ix = this
Application_ParseCLI:
	push ix
	call Application_GetCLI
	call CLI_Parse
	ld l,(ix + CLI.archivePath)
	ld h,(ix + CLI.archivePath + 1)
	ld a,l
	or h
	ld hl,Application_usageInstructions
	jp z,System_ThrowExceptionWithMessage
	pop ix
	ret

; ix = this
Application_Inflate:
	call Application_IsTesting
	jp z,Application_InflateTest
	jp Application_InflateToFile

; ix = this
Application_InflateToFile:
	call Application_PrintInflating
	push ix
	call Application_CreateFileReader
	push de
	call Application_ReadOutputSize
	call Application_IsFast
	cpl
	push ix
	call Application_GetGzipArchive
	call GzipArchive_Construct

	ex (sp),ix
	call Application_CreateFileWriter
	call Application_PreAllocateOutput
	pop ix
	push de
	call GzipArchive_Extract

	ex (sp),ix
	call FileWriter_Destruct
	pop ix
	call GzipArchive_Destruct
	pop ix
	call FileReader_Destruct
	pop ix
	ret

; ix = this
Application_InflateTest:
	call Application_PrintTesting
	push ix
	call Application_CreateFileReader
	push de
	call Application_IsFast
	cpl
	push ix
	call Application_GetGzipArchive
	call GzipArchive_Construct

	ex (sp),ix
	call Application_CreateNullWriter
	pop ix
	push de
	call GzipArchive_Extract

	ex (sp),ix
	call NullWriter_Destruct
	pop ix
	call GzipArchive_Destruct
	pop ix
	call FileReader_Destruct
	pop ix
	ret

; ix = this
Application_PrintWelcome:
	call Application_IsQuiet
	ret nz
	ld hl,Application_welcome
	jp System_Print

; ix = this
Application_PrintInflating:
	call Application_IsQuiet
	ret nz
	ld hl,Application_inflatingFile
	call System_Print
	push ix
	call Application_GetCLI
	ld l,(ix + CLI.archivePath)
	ld h,(ix + CLI.archivePath + 1)
	pop ix
	call System_Print
	ld hl,Application_dotDotDot
	jp System_Print

; ix = this
Application_PrintTesting:
	call Application_IsQuiet
	ret nz
	ld hl,Application_testingFile
	call System_Print
	push ix
	call Application_GetCLI
	ld l,(ix + CLI.archivePath)
	ld h,(ix + CLI.archivePath + 1)
	pop ix
	call System_Print
	ld hl,Application_dotDotDot
	jp System_Print

; ix = this
; f <- nz: quiet
; Modifies: none
Application_IsQuiet:
	push ix
	call Application_GetCLI
	bit 0,(ix + CLI.quiet)
	pop ix
	ret

; ix = this
; a <- -1: fast
; Modifies: f
Application_IsFast:
	push ix
	call Application_GetCLI
	ld a,(ix + CLI.fast)
	pop ix
	ret

; ix = this
; f <- z: testing
; Modifies: a
Application_IsTesting:
	push ix
	call Application_GetCLI
	ld a,(ix + CLI.outputPath)
	or (ix + CLI.outputPath + 1)
	pop ix
	ret

; ix = this
; de <- file reader
Application_CreateFileReader:
	push ix
	call Application_GetCLI
	ld e,(ix + CLI.archivePath)
	ld d,(ix + CLI.archivePath + 1)
	pop ix
	ld hl,READBUFFER
	ld bc,READBUFFER_SIZE
	push ix
	call Application_GetFileReader
	call FileReader_Construct
	pop ix
	ret

; ix = this
; de <- file writer
Application_CreateFileWriter:
	push ix
	call Application_GetCLI
	ld e,(ix + CLI.outputPath)
	ld d,(ix + CLI.outputPath + 1)
	pop ix
	ld hl,WRITEBUFFER
	ld bc,WRITEBUFFER_SIZE
	push ix
	call Application_GetFileWriter
	call FileWriter_Construct
	pop ix
	ret

; ix = this
; de <- null writer
Application_CreateNullWriter:
	ld hl,WRITEBUFFER
	ld bc,WRITEBUFFER_SIZE
	push ix
	call Application_GetNullWriter
	call NullWriter_Construct
	pop ix
	ret

; de = file reader
; ix = this
; Modifies: af, bc, hl, iy
Application_ReadOutputSize:
	ld iyl,e
	ld iyh,d
	push de
	ld b,(iy + FileReader.fileHandle)
	call DOS_GetFileHandlePointer
	call DOS_TerminateIfError
	push de
	push hl
	ld a,2
	ld hl,-4 & 0FFFFH
	ld de,-4 >> 16
	ld b,(iy + FileReader.fileHandle)
	call DOS_MoveFileHandlePointer
	call DOS_TerminateIfError
	ld e,ixl
	ld d,ixh
	ld hl,Application.outputSize
	add hl,de
	ex de,hl
	ld hl,4
	ld b,(iy + FileReader.fileHandle)
	call DOS_ReadFromFileHandle
	call DOS_TerminateIfError
	pop hl
	pop de
	ld b,(iy + FileReader.fileHandle)
	call DOS_SetFileHandlePointer
	call DOS_TerminateIfError
	pop de
	ret

; de = file writer
; ix = this
; Modifies: af, bc, hl, iy
Application_PreAllocateOutput:
	ld iyl,e
	ld iyh,d
	ld a,(ix + Application.outputSize + 2)
	or (ix + Application.outputSize + 3)
	ret z  ; don’t pre-allocate if < 64K
	push de
	ld b,(iy + FileWriter.fileHandle)
	call DOS_GetFileHandlePointer
	call DOS_TerminateIfError
	push de
	push hl
	ld l,(ix + Application.outputSize)
	ld h,(ix + Application.outputSize + 1)
	ld e,(ix + Application.outputSize + 2)
	ld d,(ix + Application.outputSize + 3)
	ld bc,1
	sbc hl,bc
	dec bc
	ex de,hl
	sbc hl,bc
	ex de,hl
	ld b,(iy + FileWriter.fileHandle)
	call DOS_SetFileHandlePointer
	call DOS_TerminateIfError
	ld de,0  ; don’t care which value we write
	ld hl,1
	ld b,(iy + FileWriter.fileHandle)
	call DOS_WriteToFileHandle
	call DOS_TerminateIfError
	pop hl
	pop de
	ld b,(iy + FileWriter.fileHandle)
	call DOS_SetFileHandlePointer
	call DOS_TerminateIfError
	pop de
	ret

; Check if the stack is well above the heap
Application_CheckStack:
	ld hl,-(HEAP + HEAP_SIZE + STACK_SIZE)
	add hl,sp
	ld hl,Application_insufficientTPAError
	jp nc,System_ThrowExceptionWithMessage
	ret

;
Application_instance:
	Application

Application_welcome:
	db "Gunzip 1.1 by Grauw",13,10,10,0

Application_inflatingFile:
	db "Inflating ",0

Application_testingFile:
	db "Testing ",0

Application_dotDotDot:
	db "...",13,10,0

Application_insufficientTPAError:
	db "Insufficient TPA space.",13,10,0

Application_usageInstructions:
	db "Usage: gunzip [options] <archive.gz> <outputfile>",13,10
	db 13,10
	db "Options:",13,10
	db "  /q  Quiet, suppress messages.",13,10
	db "  /f  Fast, no checksum validation.",13,10
	db 13,10
	db "If no output file is specified, the archive will be tested.",13,10,0
