.export clock_init
.export clock_set
.export clock_get
.export clock_run

.bss

seconds:	.res	1
minutes:	.res	1
hours:		.res	1
sseconds:	.res	1
sminutes:	.res	1
shours:		.res	1
set:		.res	1
last:		.res	1

.code

.proc clock_init
		sta	seconds
		stx	minutes
		sty	hours
		lda	#$7f
		sta	$dd0d
		sta	last
		lda	#$0
		sta	set
		sta	$dd07
		sta	$dd0e
		sta	$dd0f
		lda	$2a6
		beq	ntsc
		lda	#$89
		ldx	#$f0
		ldy	#$f
		bne	settimers
ntsc:		lda	#$de
		ldx	#$80
		ldy	#$1e
settimers:	sta	$dd04
		stx	$dd05
		sty	$dd06
starttimers:	lda	#$11
		sta	$dd0e
		lda	#$51
		sta	$dd0f
		rts
.endproc

.proc clock_set
		sta	sseconds
		stx	sminutes
		sty	shours
		inc	set
		rts
.endproc

.proc clock_get
		lda	seconds
		ldx	minutes
		ldy	hours
		sec
		rts
.endproc

.proc clock_run
		lda	set
		beq	noset
		lda	sseconds
		sta	seconds
		lda	sminutes
		sta	minutes
		lda	shours
		sta	hours
		lda	#$0
		sta	set
		lda	#$80
		sta	last
		jsr	clock_init::starttimers
		bne	clock_get
noset:		lda	$dd06
		cmp	last
		sta	last
		beq	done
		bcc	done
		lda	$2a6
		bne	nostall
		dec	$dd0e
		inc	$dd0e
nostall:	ldx	seconds
		inx
		stx	seconds
		cpx	#60
		bcc	clock_get
		ldx	#$0
		stx	seconds
		ldx	minutes
		inx
		stx	minutes
		cpx	#60
		bcc	clock_get
		ldx	#$0
		stx	minutes
		ldx	hours
		inx
		cpx	#24
		bcc	hoursok
		ldx	#$0
hoursok:	stx	hours
		bpl	clock_get
done:		clc
		rts
.endproc

