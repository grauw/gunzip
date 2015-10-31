;
; Huffman alphabet builder
;
Alphabet_MAX_CODELENGTH: equ 15

Alphabet: MACRO
	root:
		dw 0
	treeSize:
		dw 0
	treePosition:
		dw 0
	treeEnd:
		dw 0
	codeLengthCounts:
		ds Alphabet_MAX_CODELENGTH * 2, 0
	nextCodes:
		ds Alphabet_MAX_CODELENGTH * 2, 0
	_size:
	ENDM

Alphabet_class: Class Alphabet, Alphabet_template, Heap_main
Alphabet_template: Alphabet

; bc = code length table length
; de = code length table
; hl = symbol handler table
; ix = this
; ix <- this
; de <- this
Alphabet_Construct:
	push hl
	push de
	push bc
	ex de,hl
	call Alphabet_CountCodeLengths
	call Alphabet_CalculateNextCodes
	pop bc
	push bc
	call Alphabet_AllocateTreeBuffer
	pop bc
	pop de
	pop hl
	call Alphabet_BuildTree
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
Alphabet_Destruct:
	ld e,(ix + Alphabet.root)
	ld d,(ix + Alphabet.root + 1)
	ld c,(ix + Alphabet.treeSize)
	ld b,(ix + Alphabet.treeSize + 1)
	push ix
	ld ix,Heap_main
	call Heap_Free
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
	ld l,(ix + Alphabet.root)
	ld h,(ix + Alphabet.root + 1)
	jp hl

; iy = this
Alphabet_Process_IY:
	ld l,(iy + Alphabet.root)
	ld h,(iy + Alphabet.root + 1)
	jp hl

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
	and a
	call nz,Alphabet_CountCodeLength
	djnz Loop
	dec c
	jr nz,Loop
	ret

; a = code length (must not be 0)
; ix = this
; Modifies: af, de
Alphabet_CountCodeLength: PROC
	cp Alphabet_MAX_CODELENGTH + 1
	call nc,System_ThrowException
	push ix
	add a,a
	ld e,a
	ld d,0
	add ix,de
	inc (ix + Alphabet.codeLengthCounts - 2)
	call z,Overflow
	pop ix
	ret
Overflow:
	inc (ix + Alphabet.codeLengthCounts - 2 + 1)
	ret
	ENDP

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
	ld e,(ix + Alphabet.codeLengthCounts)
	ld d,(ix + Alphabet.codeLengthCounts + 1)
	inc ix
	inc ix
	add hl,de
	add hl,hl
	djnz Loop
	ld (iy + Alphabet.nextCodes),l
	ld (iy + Alphabet.nextCodes + 1),h
	pop ix
	ret
	ENDP

; bc = code length count (> 0)
; Modifies: af, bc, de, hl
Alphabet_AllocateTreeBuffer:
	call Alphabet_CalculateTreeBufferSize
	ld (ix + Alphabet.treeSize),l
	ld (ix + Alphabet.treeSize + 1),h
	push hl
	ld c,l
	ld b,h
	push ix
	ld ix,Heap_main
	call Heap_Allocate
	pop ix
	ld (ix + Alphabet.root),e
	ld (ix + Alphabet.root + 1),d
	ld (ix + Alphabet.treePosition),e
	ld (ix + Alphabet.treePosition + 1),d
	pop hl
	add hl,de
	ld (ix + Alphabet.treeEnd),l
	ld (ix + Alphabet.treeEnd + 1),h
	call Alphabet_AddBranch
	ret

; bc = code length count
; hl <- buffer size
; Modifies: af
Alphabet_CalculateTreeBufferSize: PROC
	ld a,Branch._size
	ld hl,0
Loop:
	add hl,bc
	dec a
	jp nz,Loop
	ret
	ENDP

; ix = this
; de <- branch
; Modifies: f, bc, hl
Alphabet_AddBranch:
	push bc
	ld e,(ix + Alphabet.treePosition)
	ld d,(ix + Alphabet.treePosition + 1)
	push de
	push hl
	ld hl,Branch_template
	ld bc,Branch._size
	ldir
	ld (ix + Alphabet.treePosition),e
	ld (ix + Alphabet.treePosition + 1),d
	ld l,(ix + Alphabet.treeEnd)
	ld h,(ix + Alphabet.treeEnd + 1)
	and a
	sbc hl,de
	call c,System_ThrowException
	pop hl
	pop de
	pop bc
	ret

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

; a = code length (1-15)
; de = symbol callback
; ix = this
Alphabet_AddTreeNode: PROC
	ld c,a
	ld b,0
	sla c
	push ix
	add ix,bc
	ld l,(ix + Alphabet.nextCodes - 2)
	ld h,(ix + Alphabet.nextCodes - 1)
	inc hl
	ld (ix + Alphabet.nextCodes - 2),l
	ld (ix + Alphabet.nextCodes - 1),h
	dec hl
	pop ix
	ld b,a
	ld a,16
	sub b
PreShiftLoop:
	add hl,hl
	dec a
	jp nz,PreShiftLoop
	ld a,(ix + Alphabet.root)
	ld iyl,a
	ld a,(ix + Alphabet.root + 1)
	ld iyh,a
	call Alphabet_Build
	ret
	ENDP

; b = bit length
; de = symbol callback
; hl = code (left aligned)
; iy = current branch
; ix = this
; Modifies: af, b, de, hl, iy
Alphabet_Build: PROC
	push de
NextBit:
	add hl,hl
	jp c,One
Zero:
	ld e,(iy + Branch.zero)
	ld d,(iy + Branch.zero + 1)
	ld a,d
	or e
	djnz ZeroRecurse
	call nz,System_ThrowException
	pop de
	ld (iy + Branch.zero),e
	ld (iy + Branch.zero + 1),d
	ret
ZeroRecurse:
	jr nz,ZeroExists
	call Alphabet_AddBranch
	ld (iy + Branch.zero),e
	ld (iy + Branch.zero + 1),d
ZeroExists:
	ld a,(de)
	cp Branch_ID
	call nz,System_ThrowException
	ld iyl,e
	ld iyh,d
	jp NextBit
One:
	ld e,(iy + Branch.one)
	ld d,(iy + Branch.one + 1)
	ld a,d
	or e
	djnz OneRecurse
	call nz,System_ThrowException
	pop de
	ld (iy + Branch.one),e
	ld (iy + Branch.one + 1),d
	ret
OneRecurse:
	jr nz,OneExists
	call Alphabet_AddBranch
	ld (iy + Branch.one),e
	ld (iy + Branch.one + 1),d
OneExists:
	ld a,(de)
	cp Branch_ID
	call nz,System_ThrowException
	ld iyl,e
	ld iyh,d
	jp NextBit
	ENDP
