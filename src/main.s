.import clock_init
.import clock_get
.import clock_set
.import clock_run

.segment "LDADDR"
		.word	$c000

.bss

numstr:		.res	2
nextcol:	.res	1
phase:		.res	1

.segment "SPPTR"

spptr:		.res	8

.data

vicinit:	.byte	$d8, $fc
		.byte	$e8, $fc
		.byte	$f8, $fc
		.byte	$08, $fc
		.byte	$18, $fc
		.byte	$28, $fc
		.byte	$38, $fc
		.byte	$48, $fc
		.byte	$f8
		.byte	$1b
		.byte	$32

colors:		.byte	$1, $1, $1, $d, $f, $5, $c, $8, $b, $6

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
		sta	phase
		tax
		tay
		jsr	clock_init
		jsr	clock_get
		jsr	showclock
		lda	$d021
		sta	$fe
		lda	#$8
		sta	nextcol
		lda	#$14
		sta	spptr+2
		sta	spptr+5
		lda	#$ff
		sta	$d01c
		sta	$d015
		lda	#$1
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
		ldx	#$8
spcolloop:	sta	$d027,x
		dex
		bpl	spcolloop
		dey
		sty	nextcol
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
		lda	numstr
		adc	#$a
		sta	numstr
		lda	numstr+1
		adc	#$a
		sta	numstr+1
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
