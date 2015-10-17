;
; Buffered null file writer
;
NullWriter: MACRO
	super: Writer NullWriter_Flush
	fileHandle:
		db 0FFH
	_size:
	ENDM

NullWriter_class: Class NullWriter, NullWriter_template, Heap_main
NullWriter_template: NullWriter

; hl = buffer start
; bc = buffer size
; ix = this
; ix <- this
; de <- this
NullWriter_Construct:
	call Writer_Construct
	ret

; ix = this
; ix <- this
NullWriter_Destruct:
	call Writer_Destruct
	ret

; ix = this
NullWriter_Flush:
	ld c,_CONST  ; allow ctrl-c
	call BDOS
	ret
