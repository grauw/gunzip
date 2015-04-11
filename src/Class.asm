;
; Object to define and instantiate classes
;
Class: MACRO ?macro, ?template, ?constructor, ?destructor, ?heap
	; ix <- new object
	; de <- new object
	New:
		push bc
		push hl
		ld bc,?macro._size
		ld hl,?template
		ld ix,?heap
		call Class__New
		pop hl
		pop bc
		call ?constructor
		ld e,ixl
		ld d,ixh
		ret

	; ix = object
	Destroy:
		call ?destructor
		ld bc,?macro._size
		ld e,ixl
		ld d,ixh
		ld ix,?heap
		jp Heap_Free
	ENDM

; bc = size
; ix = heap
; hl = template
Class__New:
	push af
	push de
	push hl
	call Heap_Allocate
	ld ixl,e
	ld ixh,d
	pop hl
	ldir
	pop de
	pop af
	ret
