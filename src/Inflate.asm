;
; Inflate implementation
;
Inflate: MACRO
	ENDM

; ix = this
; ix <- this
Inflate_Constructor:
	ret

; ix = this
; ix <- this
Inflate_Destructor:
	ret

; ix = this
Inflate_Inflate:
	ret

;
	SECTION RAM

Inflate_instance: Inflate

	ENDS
