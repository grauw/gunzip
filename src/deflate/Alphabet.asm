;
; Huffman alphabet builder
;
Alphabet_MAX_CODELENGTH: equ 15
Alphabet_LEAF_SIZE: equ 3

Alphabet: MACRO
	Process:
		jp 0
	root: equ $ - 2
	treeSize:
		dw 0
	treePosition:
		dw 0
	treeStart:
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
	ld a,b
	or c
	call z,System_ThrowException
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
	call Alphabet_TrapEmptyTree
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
Alphabet_Destruct:
	ld e,(ix + Alphabet.treeStart)
	ld d,(ix + Alphabet.treeStart + 1)
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
	jp ix

; iy = this
Alphabet_Process_IY:
	jp iy

; ix = this
Alphabet_TrapEmptyTree:
	ld a,(ix + Alphabet.root)
	or (ix + Alphabet.root + 1)
	ret nz
	ld (ix + Alphabet.root),System_ThrowException & 0FFH
	ld (ix + Alphabet.root + 1),System_ThrowException >> 8
	ret

; bc = code length table length
; hl = code length table
; ix = this
Alphabet_CountCodeLengths: PROC
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
	ENDP

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
	ld (ix + Alphabet.treeStart),e
	ld (ix + Alphabet.treeStart + 1),d
	ld (ix + Alphabet.treePosition),e
	ld (ix + Alphabet.treePosition + 1),d
	pop hl
	add hl,de
	ld (ix + Alphabet.treeEnd),l
	ld (ix + Alphabet.treeEnd + 1),h
	ret

; bc = code length count
; hl <- buffer size
; Modifies: af
Alphabet_CalculateTreeBufferSize: PROC
	dec bc
	ld a,Branch._size + Alphabet_LEAF_SIZE
	ld hl,0
Loop:
	add hl,bc
	dec a
	jp nz,Loop
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
	ld a,(de)
	inc de
	and a
	jr z,Skip
	push bc
	push de
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	push hl
	call Alphabet_AddTreeNode
	pop hl
	pop de
	pop bc
	djnz Loop
	dec c
	jr nz,Loop
	ret
Skip:
	inc hl
	inc hl
	djnz Loop
	dec c
	jr nz,Loop
	call Alphabet_CheckTreeBufferOverflow
	ret
	ENDP

; ix = this
Alphabet_CheckTreeBufferOverflow:
	ld e,(ix + Alphabet.treePosition)
	ld d,(ix + Alphabet.treePosition + 1)
	ld l,(ix + Alphabet.treeEnd)
	ld h,(ix + Alphabet.treeEnd + 1)
	and a
	sbc hl,de
	call c,System_ThrowException
	ret

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
	call Alphabet_Build
	ret
	ENDP

; b = bit length
; de = symbol callback
; hl = code (left aligned)
; ix = this
; Modifies: af, b, de, hl, iy
Alphabet_Build: PROC
	push de
	ld e,(ix + Alphabet.root)
	ld d,(ix + Alphabet.root + 1)
	ld iyl,e
	ld iyh,d
	ld a,e
	or d
	jp nz,Alphabet_Build_FollowPhase
First:
	call Alphabet_AddBranch
	ld (ix + Alphabet.root),e
	ld (ix + Alphabet.root + 1),d
	ld iyl,e
	ld iyh,d
	jp Alphabet_Build_GeneratePhase
	ENDP

; First we traverse the tree until we reach an open node.
; b = bit length
; (sp) = symbol callback
; hl = code (left aligned)
; iy = current branch
; ix = this
; Modifies: af, b, de, hl, iy
Alphabet_Build_FollowPhase: PROC
	add hl,hl
	sbc a,a
	and 8
	xor 0DAH  ; carry ? jp nc : jp c
	cp (iy + Branch.jump)
	jr nz,Conditional
	ld de,Branch._size
	add iy,de
	djnz Alphabet_Build_FollowPhase
	call System_ThrowException
Conditional:
	ld e,(iy + Branch.jumpAddress)
	ld d,(iy + Branch.jumpAddress + 1)
	ld a,e
	or d
	jr z,Generate
	ld iyl,e
	ld iyh,d
	djnz Alphabet_Build_FollowPhase
	call System_ThrowException
Generate:
	djnz Branch
Leaf:
	pop de
	ld (iy + Branch.jumpAddress),e
	ld (iy + Branch.jumpAddress + 1),d
	ret
Branch:
	call Alphabet_AddBranch
	ld (iy + Branch.jumpAddress),e
	ld (iy + Branch.jumpAddress + 1),d
	ld iyl,e
	ld iyh,d
	jp Alphabet_Build_GeneratePhase
	ENDP

; Then we generate branches until we reach the end.
; b = bit length
; (sp) = symbol callback
; hl = code (left aligned)
; iy = current branch
; ix = this
; Modifies: af, b, de, hl, iy
Alphabet_Build_GeneratePhase: PROC
	add hl,hl
	sbc a,a
	and 8
	xor 0DAH  ; carry ? jp nc : jp c
	ld (iy + Branch.jump),a
	djnz Branch
Leaf:
	pop de
	call Alphabet_AddLeaf
	ret
Branch:
	call Alphabet_AddBranch
	ld iyl,e
	ld iyh,d
	jp Alphabet_Build_GeneratePhase
	ENDP

; ix = this
; de <- branch
; Modifies: f
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
	pop hl
	pop de
	pop bc
	ret

; ix = this
; de = symbol handler
; Modifies: hl
Alphabet_AddLeaf:
	ld l,(ix + Alphabet.treePosition)
	ld h,(ix + Alphabet.treePosition + 1)
	ld (hl),0C3H  ; jp
	inc hl
	ld (hl),e
	inc hl
	ld (hl),d
	inc hl
	ld (ix + Alphabet.treePosition),l
	ld (ix + Alphabet.treePosition + 1),h
	ret
