;
; Top-level application program class
;
Application: MACRO
	cli:
		dw 0
	_size:
	ENDM

Application_class: Class Application, Application_template, Heap_main
Application_template: Application

;
Application_Main:
	call DOS_IsDOS2
	ld hl,Application_dos2RequiredError
	call c,Application_TerminateWithError

	ld hl,Application_welcome
	call System_Print

	ld ix,Heap_main
	call Heap_Construct

	call HeapTest_Test
	call AlphabetTest_Test

	call Application_class.New
	call Application_Construct
	ld (Application_instance),ix
	ld de,Application_Abort
	call Application_SetAbortHandler
	call Application_EnterMainLoop
	call Application_Abort
	ret

; DOS error or abort handler
Application_Abort:
	push af
	push bc
	ld ix,(Application_instance)
	call Application_Destruct
	call Application_class.Delete
	pop bc
	pop af
	ret

; de = abort handler
; ix = this
Application_SetAbortHandler:
	ld c,_DEFAB
	call BDOS
	ret

; ix = this
; ix <- this
; de <- this
Application_Construct:
	push ix
	call CLI_class.New
	call CLI_Construct
	pop ix
	ld (ix + Application.cli),e
	ld (ix + Application.cli + 1),d
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
Application_Destruct:
	push ix
	call Application_GetCLI
	call CLI_Destruct
	call CLI_class.Delete
	pop ix
	ret

; ix = this
; de <- Command-line interface
; ix <- Command-line interface
Application_GetCLI:
	ld e,(ix + Application.cli)
	ld d,(ix + Application.cli + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
Application_EnterMainLoop:
	call Application_ParseCLI
	call Application_PrintFilename
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
	call z,Application_TerminateWithError
	pop ix
	ret

; ix = this
Application_PrintFilename:
	push ix
	call Application_GetCLI
	ld l,(ix + CLI.archivePath)
	ld h,(ix + CLI.archivePath + 1)
	pop ix
	push hl
	ld hl,Application_inflatingFile
	call System_Print
	pop hl
	call System_Print
	ld hl,Application_dotDotDot
	call System_Print
	ret

; ix = this
Application_Inflate:
	push ix
	call Application_GetCLI
	ld l,(ix + CLI.outputPath)
	ld h,(ix + CLI.outputPath + 1)
	pop ix
	ld a,l
	or h
	jp z,Application_InflateTest
	jp Application_InflateToFile

; ix = this
Application_InflateToFile:
	call Application_CreateFileReader
	push de
	call Application_CreateFileWriter
	pop hl
	push ix
	push hl
	push de
	call Archive_class.New
	call Archive_Construct

	call Archive_Inflate

	call Archive_Destruct
	call Archive_class.Delete
	pop de
	ld ixl,e
	ld ixh,d
	call FileWriter_Destruct
	call FileWriter_class.Delete
	pop de
	ld ixl,e
	ld ixh,d
	call FileReader_Destruct
	call FileReader_class.Delete
	pop ix
	ret

; ix = this
Application_InflateTest:
	call Application_CreateFileReader
	push de
	call Application_CreateNullWriter
	pop hl
	push ix
	push hl
	push de
	call Archive_class.New
	call Archive_Construct

	call Archive_Inflate

	call Archive_Destruct
	call Archive_class.Delete
	pop de
	ld ixl,e
	ld ixh,d
	call NullWriter_Destruct
	call NullWriter_class.Delete
	pop de
	ld ixl,e
	ld ixh,d
	call FileReader_Destruct
	call FileReader_class.Delete
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
	ld hl,IBUFFER
	ld bc,IBUFFER_SIZE
	push ix
	call FileReader_class.New
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
	ld hl,OBUFFER
	ld bc,OBUFFER_SIZE
	push ix
	call FileWriter_class.New
	call FileWriter_Construct
	pop ix
	ret

; ix = this
; de <- file writer
Application_CreateNullWriter:
	ld hl,OBUFFER
	ld bc,OBUFFER_SIZE
	push ix
	call NullWriter_class.New
	call NullWriter_Construct
	pop ix
	ret

; a <- DOS error code
Application_CheckDOSError:
	and a
	ret z
Application_TerminateWithDOSError:
	ld b,a
	ld c,_EXPLAIN
	ld de,Application_explainBuffer
	call BDOS
	ld hl,Application_explainBuffer
	call System_Print
	call System_PrintCrLf
	ld b,1
	ld c,_TERM
	call BDOS

; hl <- message
Application_TerminateWithError:
	call System_Print
	ld b,1
	ld c,_TERM
	call BDOS

;
Application_welcome:
	db "Gunzip 1.0 by Grauw",13,10,10,0

Application_inflatingFile:
	db "Inflating ",0

Application_dotDotDot:
	db "...",13,10,0

Application_dos2RequiredError:
	db "MSX-DOS 2 is required.",13,10,0

Application_usageInstructions:
	db "Usage: gunzip [options] <file.gz> <outputfile>",13,10
	db 13,10
	db "Options:",13,10
	db "  /t  Test the checksum after inflating.",13,10,0

	SECTION RAM

Application_instance:
	dw 0

Application_explainBuffer:
	ds 64,0

	ENDS
