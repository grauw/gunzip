;
; Top-level application program class
;
Application: MACRO
	cli:
		dw CLI_instance
	archive:
		dw Archive_instance
	size:
	ENDM

;
Application_Main:
	call DOS_IsDOS2
	ld hl,Application_dos2RequiredError
	call c,Application_TerminateWithError

	ld hl,Application_welcome
	call System_Print

	ld ix,Heap_main
	call Heap_Constructor

	call HeapTest_Test

	ld ix,Application_instance
	call Application_Constructor
	ld de,Application_Abort
	call Application_SetAbortHandler
	call Application_EnterMainLoop
	call Application_Abort
	ret

; DOS error or abort handler
Application_Abort:
	push af
	push bc
	ld ix,Application_instance
	call Application_Destructor
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
Application_Constructor:
	push ix
	call Application_GetCLI
	call CLI_Constructor
	pop ix
	push ix
	call Application_GetArchive
	call Archive_Constructor
	pop ix
	ret

; ix = this
; ix <- this
Application_Destructor:
	push ix
	call Application_GetCLI
	call CLI_Destructor
	pop ix
	push ix
	call Application_GetArchive
	call Archive_Destructor
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
; de <- Gzip archive
; ix <- Gzip archive
Application_GetArchive:
	ld e,(ix + Application.archive)
	ld d,(ix + Application.archive + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
Application_EnterMainLoop:
	call Application_ParseCLI
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
	ld l,(ix + CLI.outputPath)
	ld h,(ix + CLI.outputPath + 1)
	ld a,l
	or h
	ld hl,Application_usageInstructions
	call z,Application_TerminateWithError
	pop ix
	ret

; ix = this
Application_Inflate: PROC
	push ix
	call Application_GetCLI
	ld l,(ix + CLI.archivePath)
	ld h,(ix + CLI.archivePath + 1)
	ld e,(ix + CLI.outputPath)
	ld d,(ix + CLI.outputPath + 1)
	pop ix
	push ix
	push de
	push hl
	ld hl,Application_inflatingFile
	call System_Print
	pop hl
	push hl
	call System_Print
	ld hl,Application_dotDotDot
	call System_Print
	call Application_GetArchive
	pop hl
	pop de
	call Archive_Inflate
	pop ix
	ret
	ENDP

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
	SECTION RAM

Application_instance: Application

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

Application_explainBuffer:
	ds 64,0

	ENDS
