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
HEAP_SIZE: equ 1000H
STACK_SIZE: equ 100H

TPA: ds 2E00H
RAM: ds 0100H
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
	INCLUDE "alphabet/Branch.asm"
	INCLUDE "Reader.asm"
	INCLUDE "Writer.asm"
	INCLUDE "WriterTest.asm"
	INCLUDE "FileReader.asm"
	INCLUDE "FileWriter.asm"
	INCLUDE "NullWriter.asm"

	ALIGN 100H
CRC32Table:
	INCLUDE "crctable.asm"

	ENDS

	SECTION RAM

Heap_main:
	Heap HEAP, HEAP_SIZE

	ENDS
