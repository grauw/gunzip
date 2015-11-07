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
	treePosition:
		dw 0
	treeStart:
		dw 0
	treeEnd:
		dw 0
	codeLengthCounts:
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
	ld (ix + Alphabet.codeLengthCount),c
	ld (ix + Alphabet.codeLengthCount + 1),b
	ld (ix + Alphabet.codeLengths),e
	ld (ix + Alphabet.codeLengths + 1),d
	ld (ix + Alphabet.symbolHandlers),l
	ld (ix + Alphabet.symbolHandlers + 1),h
	call Alphabet_CountCodeLengths
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

; ix = this
Alphabet_TrapEmptyTree:
	ld a,(ix + Alphabet.root)
	or (ix + Alphabet.root + 1)
	ret nz
	ld (ix + Alphabet.root),System_ThrowException & 0FFH
	ld (ix + Alphabet.root + 1),System_ThrowException >> 8
	ret

; ix = this
Alphabet_CountCodeLengths: PROC
	ld e,(ix + Alphabet.codeLengthCount)
	ld d,(ix + Alphabet.codeLengthCount + 1)
	ld l,(ix + Alphabet.codeLengths)
	ld h,(ix + Alphabet.codeLengths + 1)
	ld b,e  ; convert 16-bit counter de to two 8-bit counters in b and c
	dec de
	inc d
	ld c,d
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
Alphabet_BuildTree:
	call Alphabet_GetFirstSymbol
	jp c,Alphabet_TrapEmptyTree
	ld l,(ix + Alphabet.treePosition)
	ld h,(ix + Alphabet.treePosition + 1)
	ld (ix + Alphabet.root),l
	ld (ix + Alphabet.root + 1),h
	call Alphabet_BuildBranch
	call Alphabet_CheckTreeBufferOverflow
	ret

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

; b = bits left
; de = symbol handler
; iy = current branch
; ix = this
Alphabet_BuildBranch:
	push iy
	push de
	call Alphabet_AddBranch
	ld iyl,e
	ld iyh,d
	pop de
	call Alphabet_BuildBranchZero
	call nc,Alphabet_BuildBranchOne
	pop iy
	ret

; b = bits left
; de = symbol handler
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
	ld l,(ix + Alphabet.treePosition)
	ld h,(ix + Alphabet.treePosition + 1)
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
