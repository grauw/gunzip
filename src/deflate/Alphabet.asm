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
	sortedCodeLengths:
		dw 0
	codeLengthCounts:
		ds Alphabet_MAX_CODELENGTH * 2
	_size:
	ENDM

; bc = code length table length
; de = code length table
; hl = symbol handler table
; ix = this
; ix <- this
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
	call Alphabet_SortCodeLengths
	call Alphabet_BuildTree
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
; Modifies: de
Alphabet_GetRoot:
	ld e,(ix + Alphabet.root)
	ld d,(ix + Alphabet.root + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
Alphabet_Process:
	jp ix

; Modifies: af, bc, de, hl
Alphabet_AllocateTreeBuffer:
	call Alphabet_CalculateTreeBufferSize
	inc hl  ; +1 extra for sentinel byte
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

; Generate list of (code length, symbol) pairs, sorted by code length
; ix = this
Alphabet_SortCodeLengths: PROC
	call Alphabet_InitCodeLengthsTable
	exx
	ld l,(ix + Alphabet.symbolHandlers)
	ld h,(ix + Alphabet.symbolHandlers + 1)
	exx
	ld l,(ix + Alphabet.codeLengths)
	ld h,(ix + Alphabet.codeLengths + 1)
	ld e,(ix + Alphabet.codeLengthCount)
	ld d,(ix + Alphabet.codeLengthCount + 1)
	ld b,e  ; convert 16-bit counter de to two 8-bit counters in b and c
	dec de
	inc d
	ld c,d
Loop:
	ld a,(hl)
	inc hl
	add a,a
	jr z,Skip
	exx
	ld e,a
	ld d,0
	push ix
	add ix,de
	ld e,(ix + Alphabet.codeLengthCounts - 2)
	ld d,(ix + Alphabet.codeLengthCounts - 1)
	rrca
	ld (de),a
	inc de
	ldi
	ldi
	ld (ix + Alphabet.codeLengthCounts - 2),e
	ld (ix + Alphabet.codeLengthCounts - 1),d
	pop ix
	exx
SkipContinue:
	djnz Loop
	dec c
	jr nz,Loop
	ret
Skip:
	exx
	inc hl
	inc hl
	exx
	jp SkipContinue
	ENDP

; ix = this
Alphabet_InitCodeLengthsTable: PROC
	call Alphabet_CountCodeLengths
	call Alphabet_GetSortedCodeLengthsStart
	ld (ix + Alphabet.sortedCodeLengths),l
	ld (ix + Alphabet.sortedCodeLengths + 1),h
	ld b,Alphabet_MAX_CODELENGTH
	push ix
Loop:
	ld e,(ix + Alphabet.codeLengthCounts)
	ld d,(ix + Alphabet.codeLengthCounts + 1)
	ld (ix + Alphabet.codeLengthCounts),l
	ld (ix + Alphabet.codeLengthCounts + 1),h
	inc ix
	inc ix
	add hl,de
	add hl,de
	add hl,de
	djnz Loop
	ld (hl),0
	pop ix
	ret
	ENDP

; ix = this
; hl <- sorted code lengths start address
Alphabet_GetSortedCodeLengthsStart:
	ld e,(ix + Alphabet.codeLengthCount)
	ld d,(ix + Alphabet.codeLengthCount + 1)
	ld l,e
	ld h,d
	add hl,hl
	add hl,de  ; x3
	ex de,hl
	ld l,(ix + Alphabet.treeEnd)
	ld h,(ix + Alphabet.treeEnd + 1)
	scf        ; +1 extra for sentinel byte
	sbc hl,de
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
	exx
	ld e,ixl
	ld d,ixh
	ld hl,Alphabet.codeLengthCounts
	add hl,de
	ld e,l
	ld d,h
	inc de
	ld (hl),0
	ld bc,Alphabet_MAX_CODELENGTH * 2 - 1
	ldir
	ld hl,-Alphabet_MAX_CODELENGTH * 2 - 2
	add hl,de
	ex de,hl  ; de = ix + Alphabet.codeLengthCounts - 2
	exx
Loop:
	ld a,(hl)
	inc hl
	and a
	jr z,Skip
	cp Alphabet_MAX_CODELENGTH + 1
	call nc,System_ThrowException
	exx
	add a,a
	ld l,a
	ld h,0
	add hl,de
	inc (hl)
	jr z,Overflow
OverflowContinue:
	exx
Skip:
	djnz Loop
	dec c
	jr nz,Loop
	ret
Overflow:
	inc hl
	inc (hl)
	jp OverflowContinue
	ENDP

; ix = this
Alphabet_BuildTree: PROC
	ld l,(ix + Alphabet.sortedCodeLengths)
	ld h,(ix + Alphabet.sortedCodeLengths + 1)
	ld c,0
	call Alphabet_GetNextSymbol
	jp z,TrapEmptyTree
	ld e,(ix + Alphabet.treeStart)
	ld d,(ix + Alphabet.treeStart + 1)
	ld (ix + Alphabet.root),e
	ld (ix + Alphabet.root + 1),d
	call Alphabet_BuildBranch
	ld l,(ix + Alphabet.treeEnd)
	ld h,(ix + Alphabet.treeEnd + 1)
	scf        ; +1 extra for sentinel byte
	sbc hl,de
	call c,System_ThrowException
	ret
TrapEmptyTree:
	ld (ix + Alphabet.root),System_ThrowException & 0FFH
	ld (ix + Alphabet.root + 1),System_ThrowException >> 8
	ret
	ENDP

; b = bits left
; c = code length
; de = tree position
; hl = sorted (code length, symbol) list pointer
; ix = this
; f <- c: end reached, z: no bits left
Alphabet_BuildBranch:
	push iy
	call Alphabet_AddBranch
	call Alphabet_BuildBranchZero
	call nc,Alphabet_BuildBranchOne
	pop iy
	ret

; b = bits left
; c = code length
; de = tree position
; hl = sorted (code length, symbol) list pointer
; iy = current branch
; ix = this
; f <- c: end reached, z: no bits left
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
; c = code length
; de = tree position
; hl = sorted (code length, symbol) list pointer
; iy = current branch
; ix = this
; f <- c: end reached, z: no bits left
Alphabet_BuildBranchOne: PROC
	djnz Branch
Leaf:
	inc hl
	ld a,(hl)
	inc hl
	ld (iy + Branch.jumpAddress),a
	ld a,(hl)
	inc hl
	ld (iy + Branch.jumpAddress + 1),a
	call Alphabet_GetNextSymbol
	inc b
	ret
Branch:
	ld (iy + Branch.jumpAddress),e
	ld (iy + Branch.jumpAddress + 1),d
	call Alphabet_BuildBranch
	inc b
	ret
	ENDP

; c = code length
; hl = sorted (code length, symbol) list pointer
; ix = this
; b <- bits left
; c <- new code length
; f <- c: negative bits left, z: no bits left
Alphabet_GetNextSymbol:
	ld a,(hl)
	sub c
	ld c,(hl)
	ld b,a
	ret

; ix = this
; de = tree position
; de <- updated tree position
; iy <- branch
; Modifies: f
Alphabet_AddBranch:
	push bc
	push hl
	ld iyl,e
	ld iyh,d
	ld hl,Branch_template
	ld bc,Branch._size
	ldir
	pop hl
	pop bc
	ret

; ix = this
; de = tree position
; hl = sorted (code length, symbol) list pointer
; de <- updated tree position
; Modifies: hl
Alphabet_AddLeaf:
	ld a,0C3H  ; jp
	ld (de),a
	inc de
	inc hl
	ldi
	ldi
	inc bc
	inc bc
	ret
