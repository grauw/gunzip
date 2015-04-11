;
; Object to define and instantiate classes
;
Class: MACRO ?macro, ?template, ?constructor, ?destructor, ?heap
	; ix <- new object
	; de <- new object
	New:
		push af
		push bc
		push de
		push hl
		ld ix,?heap
		ld bc,?macro._size
		call Heap_Allocate
		ld ixl,e
		ld ixh,d
		ld hl,?template
		ldir
		pop hl
		pop de
		pop bc
		pop af
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
