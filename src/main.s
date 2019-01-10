.import clock_init
.import clock_get
.import clock_set
.import clock_run

.segment "LDADDR"
.ifdef DEFFONT
		.word	$c2c0
.else
		.word	$c000
.endif

.bss

numstr:		.res	2

.ifndef DEFFONT
nextcol:	.res	1
phase:		.res	1
.endif

.segment "SPPTR"

spptr:		.res	8

.data

.ifndef DEFFONT
colors:		.byte	$1, $1, $1, $d, $f, $5, $c, $8, $b, $6

vicinit:	.byte	$d8, $fc
		.byte	$e8, $fc
		.byte	$f8, $fc
		.byte	$08, $fc
		.byte	$18, $fc
		.byte	$28, $fc
		.byte	$38, $fc
		.byte	$48, $fc
		.byte	$f8
.else
vicinit:	.byte	$18, $fb
		.byte	$20, $fb
		.byte	$28, $fb
		.byte	$30, $fb
		.byte	$38, $fb
		.byte	$40, $fb
		.byte	$48, $fb
		.byte	$50, $fb
		.byte	$ff
.endif
		.byte	$1b
		.byte	$32

.code
		lda	#$7f
		sta	$dc0d
		lda	$dc0d
		lda	#<isr0
		sta	$314
		lda	#>isr0
		sta	$315
		lda	#<gonehook
		sta	$308
		lda	#>gonehook
		sta	$309
		ldx	#$12
vicloop:	lda	vicinit,x
		sta	$d000,x
		dex
		bpl	vicloop
		lda	#$0
		sta	$ffff
		sta	$d017
		sta	$d01d
.ifdef DEFFONT
		sta	$d01c
		ldx	#$bf
		stx	clearloop+2
		ldx	#$40
		ldy	#$3
clearloop:	sta	$bfc0,x
		inx
		bne	clearloop
		inc	clearloop+2
		dey
		bne	clearloop
.else
		sta	phase
.endif
		tax
		tay
		jsr	clock_init
		jsr	clock_get
		jsr	showclock
		lda	$d021
		sta	$fe
.ifndef DEFFONT
		lda	#$8
		sta	nextcol
.endif
		lda	#$a
		sta	spptr+2
		sta	spptr+5
		lda	#$ff
		sta	$d015
.ifndef DEFFONT
		sta	$d01c
.else
		lda	#$33
		sta	$1
		ldx	#$7
		ldy	#$15
initdigits:	lda	$d180,x
		sta	$c000,y
		lda	$d188,x
		sta	$c040,y
		lda	$d190,x
		sta	$c080,y
		lda	$d198,x
		sta	$c0c0,y
		lda	$d1a0,x
		sta	$c100,y
		lda	$d1a8,x
		sta	$c140,y
		lda	$d1b0,x
		sta	$c180,y
		lda	$d1b8,x
		sta	$c1c0,y
		lda	$d1c0,x
		sta	$c200,y
		lda	$d1c8,x
		sta	$c240,y
		lda	$d1d0,x
		sta	$c280,y
		dey
		dey
		dey
		dex
		bpl	initdigits
		lda	#$37
		sta	$1
.endif
		lda	#$1
.ifdef DEFFONT
		ldx	#$7
colloop:	sta	$d027,x
		dex
		bpl	colloop
.endif
		sta	$d01a
		rts

.proc isr0
		asl	$d019
		lda	#$1b
		sta	$d011
		lda	$fe
		sta	$d021
		lda	$dd00
		ora	#$3
		sta	$dd00
		lda	#$fa
		sta	$d012
		lda	#<isr1
		sta	$314
		lda	#>isr1
		sta	$315
		jsr	clock_run
		bcc	docols
		jsr	showclock
.ifndef DEFFONT
		lda	#$8
		sta	nextcol
docols:		ldy	nextcol
		beq	done
		lda	#$ff
		eor	phase
		sta	phase
		beq	done
		lda	colors+1,y
		sta	$d026
		lda	colors,y
		sta	$d025
		lda	colors-1,y
		ldx	#$7
spcolloop:	sta	$d027,x
		dex
		bpl	spcolloop
		dey
		sty	nextcol
.else
docols:
.endif
done:		jmp	$ea31
.endproc

.proc isr1
		asl	$d019
		lda	#$13
		sta	$d011
		lda	$d021
		sta	$fe
		lda	$d020
		sta	$d021
		lda	$dd00
		and	#$fc
		sta	$dd00
		lda	#<isr0
		sta	$314
		lda	#>isr0
		sta	$315
		lda	#$32
		sta	$d012
		jmp	$ea81
.endproc

.proc showclock
		stx	$fb
		sty	$fc
		jsr	bytetoptr
		lda	numstr
		sta	spptr+6
		lda	numstr+1
		sta	spptr+7
		lda	$fb
		jsr	bytetoptr
		lda	numstr
		sta	spptr+3
		lda	numstr+1
		sta	spptr+4
		lda	$fc
		jsr	bytetoptr
		lda	numstr
		sta	spptr
		lda	numstr+1
		sta	spptr+1
		rts
.endproc

.proc bytetoptr
		sta	$2
		lda	#$0
		sta	numstr
		sta	numstr+1
		ldy	#$8
bcdloop:	lda	numstr+1
		cmp	#$5
		bmi	noadd
		adc	#$2
		sta	numstr+1
noadd:		asl	$2
		lda	numstr+1
		rol	a
		cmp	#$10
		and	#$f
		sta	numstr+1
		rol	numstr
		dey
		bne	bcdloop
		rts
.endproc

.proc gonehook
		jsr	$0073
		php
		cmp	#'@'
		beq	checkcmd
		plp
		jmp	$a7e7
checkcmd:	plp
		jsr	$0073
		cmp	#'t'
		beq	settimecmd
		jmp	$af08
settimecmd:	jsr	$b1b2
		lda	$65
		sta	ldhours+1
		jsr	$b79b
		stx	ldminutes+1
		jsr	$b79b
		txa
ldminutes:	ldx	#$ff
ldhours:	ldy	#$ff
		jsr	clock_set
		jmp	$a7ae
.endproc
