;
; Application
;
; gzip file decompressor
;

	INCLUDE "Macros.asm"

DEBUG: equ 1

	org 100H

IBUFFER_SIZE: equ 1000H
OBUFFER_SIZE: equ 8000H
HEAP_SIZE: EQU 1000H

TPA: ds 1F00H
RAM: ds 1000H
IBUFFER: ds VIRTUAL IBUFFER_SIZE
OBUFFER: ds VIRTUAL OBUFFER_SIZE
HEAP: ds VIRTUAL HEAP_SIZE

	SECTION TPA

;
; Program entry point
;
COM_Main:
	jp Application_Main

	INCLUDE "DOS.asm"
	INCLUDE "BIOS.asm"
	INCLUDE "System.asm"
	INCLUDE "Heap.asm"
	INCLUDE "HeapTest.asm"
	INCLUDE "Class.asm"
	INCLUDE "Application.asm"
	INCLUDE "CLI.asm"
	INCLUDE "Archive.asm"
	INCLUDE "Inflate.asm"
	INCLUDE "alphabet/Alphabet.asm"
	INCLUDE "alphabet/AlphabetTest.asm"
	INCLUDE "FileReader.asm"
	INCLUDE "FileWriter.asm"

	ALIGN 100H
CRC32Table:
	INCLUDE "crctable.asm"

	ENDS

	SECTION RAM

Heap_main:
	Heap HEAP, HEAP_SIZE

	ENDS
