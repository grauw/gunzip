;
; Gunzip
;
; gzip file decompressor
;

	INCLUDE "Macros.asm"

DEBUG: equ 1

	org 100H

IBUFFER_SIZE: equ 1000H
OBUFFER_SIZE: equ 8000H

TPA: ds 1F00H
RAM: ds 1000H
IBUFFER: ds VIRTUAL IBUFFER_SIZE
OBUFFER: ds VIRTUAL OBUFFER_SIZE

	SECTION TPA

;
; Program entry point
;
COM_Main:
	jp Gunzip_Main

	INCLUDE "DOS.asm"
	INCLUDE "BIOS.asm"
	INCLUDE "System.asm"
	INCLUDE "Heap.asm"
	INCLUDE "Class.asm"
	INCLUDE "Gunzip.asm"
	INCLUDE "CLI.asm"
	INCLUDE "Archive.asm"
	INCLUDE "Inflate.asm"

	ENDS
