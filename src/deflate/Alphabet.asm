;
; Huffman alphabet builder
;
Alphabet_MAX_CODELENGTH: equ 15
Alphabet_LEAF_SIZE: equ 3

Alphabet: MACRO
	Process:
		jp 0
	root: equ $ - 2
	codeLengthCount:
		dw 0
	codeLengths:
		dw 0
	symbolHandlers:
		dw 0
	treeSize:
		dw 0
	treeStart:
		dw 0
	treeEnd:
		dw 0
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
	ld (ix + Alphabet.codeLengthCount),c
	ld (ix + Alphabet.codeLengthCount + 1),b
	ld (ix + Alphabet.codeLengths),e
	ld (ix + Alphabet.codeLengths + 1),d
	ld (ix + Alphabet.symbolHandlers),l
	ld (ix + Alphabet.symbolHandlers + 1),h
	call Alphabet_AllocateTreeBuffer
	call Alphabet_BuildTree
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
	pop hl
	add hl,de
	ld (ix + Alphabet.treeEnd),l
	ld (ix + Alphabet.treeEnd + 1),h
	ret

; hl <- buffer size
; Modifies: af
Alphabet_CalculateTreeBufferSize: PROC
	ld c,(ix + Alphabet.codeLengthCount)
	ld b,(ix + Alphabet.codeLengthCount + 1)
	ld a,Branch._size + Alphabet_LEAF_SIZE
	ld hl,0
Loop:
	add hl,bc
	dec a
	jp nz,Loop
	ret
	ENDP

; ix = this
Alphabet_BuildTree: PROC
	call Alphabet_GetFirstSymbol
	jp c,TrapEmptyTree
	ld l,(ix + Alphabet.treeStart)
	ld h,(ix + Alphabet.treeStart + 1)
	ld (ix + Alphabet.root),l
	ld (ix + Alphabet.root + 1),h
	call Alphabet_BuildBranch
	ld e,(ix + Alphabet.treeEnd)
	ld d,(ix + Alphabet.treeEnd + 1)
	scf
	sbc hl,de
	call nc,System_ThrowException
	ret
TrapEmptyTree:
	ld (ix + Alphabet.root),System_ThrowException & 0FFH
	ld (ix + Alphabet.root + 1),System_ThrowException >> 8
	ret
	ENDP

; b = bits left
; de = symbol handler
; hl = tree position
; iy = current branch
; ix = this
Alphabet_BuildBranch:
	push iy
	call Alphabet_AddBranch
	call Alphabet_BuildBranchZero
	call nc,Alphabet_BuildBranchOne
	pop iy
	ret

; b = bits left
; de = symbol handler
; hl = tree position
; iy = current branch
; ix = this
Alphabet_BuildBranchZero: PROC
	djnz Branch
Leaf:
	call Alphabet_AddLeaf
	call Alphabet_GetNextSymbol
	inc b
	ret
Branch:
	call Alphabet_BuildBranch
	inc b
	ret
	ENDP

; b = bits left
; de = symbol handler
; hl = tree position
; iy = current branch
; ix = this
Alphabet_BuildBranchOne: PROC
	djnz Branch
Leaf:
	ld (iy + Branch.jumpAddress),e
	ld (iy + Branch.jumpAddress + 1),d
	call Alphabet_GetNextSymbol
	inc b
	ret
Branch:
	ld (iy + Branch.jumpAddress),l
	ld (iy + Branch.jumpAddress + 1),h
	call Alphabet_BuildBranch
	inc b
	ret
	ENDP

; b = bits left
; c = code length
; bc' = code lengths remaining
; de' = symbol handler table position
; hl' = code length table position
; ix = this
; b, c, bc', de', hl' <- updated
; de <- symbol handler
; f <- c: end reached
Alphabet_GetNextSymbol: PROC
NextLengthLoop:
	ld a,c
	exx
Loop:
	cpi
	jp po,NextLength
	inc de
	inc de
	jp nz,Loop
	dec de
	dec de
	ld a,(de)
	inc de
	exx
	ld e,a
	exx
	ld a,(de)
	inc de
	exx
	ld d,a
	and a  ; nc
	ret
NextLength:
	ld c,(ix + Alphabet.codeLengthCount)
	ld b,(ix + Alphabet.codeLengthCount + 1)
	inc bc
	ld l,(ix + Alphabet.codeLengths)
	ld h,(ix + Alphabet.codeLengths + 1)
	ld e,(ix + Alphabet.symbolHandlers)
	ld d,(ix + Alphabet.symbolHandlers + 1)
	exx
	cp Alphabet_MAX_CODELENGTH
	scf
	ret z
	inc c
	inc b
	jp NextLengthLoop
	ENDP

; ix = this
; b <- bits left
; c <- code length
; de <- symbol handler
; bc' <- code lengths remaining
; de' <- symbol handler table position
; hl' <- code length table position
; f <- c: end reached
Alphabet_GetFirstSymbol:
	ld bc,0
	exx
	ld bc,1
	exx
	jp Alphabet_GetNextSymbol

; ix = this
; hl = tree position
; hl <- updated tree position
; iy <- branch
; Modifies: f
Alphabet_AddBranch:
	push bc
	push de
	ex de,hl
	ld iyl,e
	ld iyh,d
	ld hl,Branch_template
	ld bc,Branch._size
	ldir
	ex de,hl
	pop de
	pop bc
	ret

; ix = this
; de = symbol handler
; hl <- updated tree position
; Modifies: hl
Alphabet_AddLeaf:
	ld (hl),0C3H  ; jp
	inc hl
	ld (hl),e
	inc hl
	ld (hl),d
	inc hl
	ret
