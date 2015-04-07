;
; Top-level Gunzip program class
;
Gunzip: MACRO
	cli:
		dw CLI_instance
	archive:
		dw Archive_instance
	size:
	ENDM

;
Gunzip_Main:
	call DOS_IsDOS2
	ld hl,Gunzip_dos2RequiredError
	call c,Gunzip_TerminateWithError

	ld hl,Gunzip_welcome
	call System_Print

	ld ix,Heap_heap
	call Heap_Constructor
	ld ix,Heap_heapUpper
	call Heap_Constructor

	call Heap_UnitTest

	ld ix,Gunzip_instance
	call Gunzip_Constructor
	ld de,Gunzip_Abort
	call Gunzip_SetAbortHandler
	call Gunzip_EnterMainLoop
	call Gunzip_Abort
	ret

; DOS error or abort handler
Gunzip_Abort:
	push af
	push bc
	ld ix,Gunzip_instance
	call Gunzip_Destructor
	pop bc
	pop af
	ret

; de = abort handler
; ix = this
Gunzip_SetAbortHandler:
	ld c,_DEFAB
	call BDOS
	ret

; ix = this
; ix <- this
Gunzip_Constructor:
	push ix
	call Gunzip_GetCLI
	call CLI_Constructor
	pop ix
	push ix
	call Gunzip_GetArchive
	call Archive_Constructor
	pop ix
	ret

; ix = this
; ix <- this
Gunzip_Destructor:
	push ix
	call Gunzip_GetCLI
	call CLI_Destructor
	pop ix
	push ix
	call Gunzip_GetArchive
	call Archive_Destructor
	pop ix
	ret

; ix = this
; de <- Command-line interface
; ix <- Command-line interface
Gunzip_GetCLI:
	ld e,(ix + Gunzip.cli)
	ld d,(ix + Gunzip.cli + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
; de <- Gzip archive
; ix <- Gzip archive
Gunzip_GetArchive:
	ld e,(ix + Gunzip.archive)
	ld d,(ix + Gunzip.archive + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
Gunzip_EnterMainLoop:
	call Gunzip_ParseCLI
	call Gunzip_Inflate
	ret

; ix = this
Gunzip_ParseCLI:
	push ix
	call Gunzip_GetCLI
	call CLI_Parse
	ld l,(ix + CLI.path)
	ld h,(ix + CLI.path + 1)
	ld a,l
	or h
	ld hl,Gunzip_usageInstructions
	call z,Gunzip_TerminateWithError
	pop ix
	ret

; ix = this
Gunzip_Inflate: PROC
	push ix
	call Gunzip_GetCLI
	ld l,(ix + CLI.path)
	ld h,(ix + CLI.path + 1)
	pop ix
	push ix
	push hl
	ld hl,Gunzip_inflatingFile
	call System_Print
	pop hl
	push hl
	call System_Print
	ld hl,Gunzip_dotDotDot
	call System_Print
	call Gunzip_GetArchive
	pop hl
	call Archive_Inflate
	pop ix
	ret
	ENDP

; a <- DOS error code
Gunzip_CheckDOSError:
	and a
	ret z
Gunzip_TerminateWithDOSError:
	ld b,a
	ld c,_EXPLAIN
	ld de,Gunzip_explainBuffer
	call BDOS
	ld hl,Gunzip_explainBuffer
	call System_Print
	call System_PrintCrLf
	ld b,1
	ld c,_TERM
	call BDOS

; hl <- message
Gunzip_TerminateWithError:
	call System_Print
	ld b,1
	ld c,_TERM
	call BDOS

;
	SECTION RAM

Gunzip_instance: Gunzip

Gunzip_welcome:
	db "Gunzip 1.0 by Grauw",13,10,10,0

Gunzip_inflatingFile:
	db "Inflating ",0

Gunzip_dotDotDot:
	db "...",13,10,0

Gunzip_dos2RequiredError:
	db "MSX-DOS 2 is required.",13,10,0

Gunzip_usageInstructions:
	db "Usage: gunzip [options] <file.gz>",13,10
	db 13,10
	db "Options:",13,10
	db "  /t  Test the checksum after inflating.",13,10,0

Gunzip_explainBuffer:
	ds 64,0

	ENDS
