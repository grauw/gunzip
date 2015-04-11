; iy = class template
; ix <- new object
; Modifies: af, bc, de, hl, ix
Class_New:
	ld ix,Heap_main
	ld c,(iy - 2)
	ld b,(iy - 1)
	call Heap_Allocate
	push de
	push iy
	pop hl
	ldir
	pop ix
	ret

; iy = class template
; ix = this
Class_Destroy:
	ld c,(iy - 2)
	ld b,(iy - 1)
	ld e,ixl
	ld d,ixh
	ld ix,Heap_main
	jp Heap_Free

; iy = class template
; de = destination address
; ix <- new object
; Modifies: bc, de, hl, ix
Class_Copy:
	ld c,(iy - 2)
	ld b,(iy - 1)
	push de
	push iy
	pop hl
	ldir
	pop ix
	ret
