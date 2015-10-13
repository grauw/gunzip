;
; Huffman alphabet builder
;
; Allocate the whole damn thing on stack...?
; So we can destroy it easily without fragmenting the heap.
;
Alphabet_MAX_CODELENGTH: equ 16

Alphabet: MACRO
	; ix = inflate object
	Process:
		jp 0
	root: equ $ - 2
	codeLengthCounts:
		ds Alphabet_MAX_CODELENGTH + 1, 0  ; allocate on stack?
	nextCodes:
		ds Alphabet_MAX_CODELENGTH * 2, 0
	_size:
	ENDM

Alphabet_class: Class Alphabet, Alphabet_template, Heap_main
Alphabet_template: Alphabet

; ix = this
; ix <- this
; de <- this
Alphabet_Construct:
	push ix
	call Branch_class.New
	call Branch_Construct
	pop ix
	ld (ix + Alphabet.root),e
	ld (ix + Alphabet.root + 1),d
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
Alphabet_Destruct:
	push ix
	call Alphabet_GetRoot
	call Branch_Destruct
	call Branch_class.Delete
	pop ix
	ret

; ix = this
; ix <- root branch
; de <- root branch
Alphabet_GetRoot:
	ld e,(ix + Alphabet.root)
	ld d,(ix + Alphabet.root + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
Alphabet_Process:
	jp ix

; iy = this
Alphabet_Process_IY:
	jp iy

; hl = this
Alphabet_Process_Jump_HL: MACRO
	jp hl
	ENDM

; bc = code length table length
; de = code length table
; hl = symbol handler table
; ix = this
Alphabet_Initialize:
	push bc
	push de
	push hl
	ex de,hl
	call Alphabet_CountCodeLengths
	call Alphabet_CalculateNextCodes
	pop hl
	pop de
	pop bc
	call Alphabet_BuildTree
	ret

; bc = code length table length
; hl = code length table
; ix = this
Alphabet_CountCodeLengths:
	ld a,c  ; convert 16-bit counter bc to two 8-bit counters in b and c
	dec bc
	inc b
	ld c,b
	ld b,a
Loop:
	ld a,(hl)
	inc hl
	call Alphabet_CountCodeLength
	djnz Loop
	dec c
	jr nz,Loop
	ret

; a = code length
; ix = this
; Modifies: af, de
Alphabet_CountCodeLength:
	cp Alphabet_MAX_CODELENGTH + 1
	call nc,System_ThrowException
	push ix
	ld e,a
	ld d,0
	add ix,de
	inc (ix + Alphabet.codeLengthCounts)
	call z,System_ThrowException
	pop ix
	ret

; ix = this
Alphabet_CalculateNextCodes: PROC
	push ix
	push ix
	pop iy
	ld hl,0  ; code
	ld b,Alphabet_MAX_CODELENGTH - 1
Loop:
	ld (iy + Alphabet.nextCodes),l
	ld (iy + Alphabet.nextCodes + 1),h
	inc iy
	inc iy
	ld e,(ix + Alphabet.codeLengthCounts + 1)
	ld d,0
	inc ix
	add hl,de
	add hl,hl
	djnz Loop
	ld (iy + Alphabet.nextCodes),l
	ld (iy + Alphabet.nextCodes + 1),h
	pop ix
	ret
	ENDP

; bc = code length table length
; de = code length table
; hl = symbol handler table
; ix = this
Alphabet_BuildTree: PROC
	ld a,c  ; convert 16-bit counter bc to two 8-bit counters in b and c
	dec bc
	inc b
	ld c,b
	ld b,a
Loop:
	push bc
	ld a,(de)
	inc de
	push de
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	push hl
	and a
	call nz,Alphabet_AddTreeNode
	pop hl
	pop de
	pop bc
	djnz Loop
	dec c
	jr nz,Loop
	ret
	ENDP

; a = code length (> 0)
; de = symbol callback
Alphabet_AddTreeNode: PROC
	ld iyl,e
	ld iyh,d
	ld b,a
	add a,a
	ld e,a
	ld d,0
	push ix
	add ix,de
	ld l,(ix + Alphabet.nextCodes - 2)
	ld h,(ix + Alphabet.nextCodes - 1)
	inc hl
	ld (ix + Alphabet.nextCodes - 2),l
	ld (ix + Alphabet.nextCodes - 1),h
	dec hl
	pop ix
	ld a,16
	sub b
	jr z,NoPreShift
PreShiftLoop:
	add hl,hl
	dec a
	jp nz,PreShiftLoop
NoPreShift:
	push ix
	call Alphabet_GetRoot
	call Branch_Build
	pop ix
	ret
	ENDP
