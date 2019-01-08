.export clock_init
.export clock_set
.export clock_get
.export clock_run

.bss

; clock values
seconds:	.res	1
minutes:	.res	1
hours:		.res	1

; temporary values for setting the clock
sseconds:	.res	1
sminutes:	.res	1
shours:		.res	1

; flag whether setting the clock was requested
set:		.res	1

; last value of CIA#2 timer B, to detect underflows without interrupt
last:		.res	1

.code

; initialize and start the clock
; in:
;   A - seconds
;   X - minutes
;   Y - hours
; out:
;   <nothing>
.proc clock_init
		sta	seconds		; set clock to value
		stx	minutes		; given in A/X/Y
		sty	hours
		lda	#$7f		; disable all interrupts on CIA#2
		sta	$dd0d		; and initialize "last" to something
		sta	last		; larger than any timer B value
		lda	#$0
		sta	set		; clear flag for setting clock
		sta	$dd07		; and high-byte of timer B
		sta	$dd0e		; stop timer A
		sta	$dd0f		; stop timer B
		lda	$2a6		; check system flag for NTSC
		beq	ntsc

		; for PAL timing, we need to count 985248 cycles per second
		; which is $f08a0, so we count $f08a cycles with timer A and
		; $10 underflows of timer A with timer B. Because the timers
		; fire on underflow (so, a value of 0 counts once more before
		; firing), we need to subtract 1 from the values

		lda	#$89		; lowbyte of $f08a - 1
		ldx	#$f0		; highbyte of $f08a - 1
		ldy	#$f		; $10 - 1
		bne	settimers	; and set these values

		; for NTSC timing, we need to count 1022727 cycles per second.
		; Unfortunately, this is a prime -- but 1022721 isn't, it's
		; 31 * 32991, in hex $1f * $80df. So we use this and care about
		; the additional 6 cycles later

ntsc:		lda	#$de		; lowbyte of $80df - 1
		ldx	#$80		; highbyte of $80df - 1
		ldy	#$1e		; $1f - 1
settimers:	sta	$dd04		; set timer A lowbyte
		stx	$dd05		; set timer A highbyte
		sty	$dd06		; set timer B lowbyte

starttimers:	lda	#$11		; start timer A counting cycles
		sta	$dd0e
		lda	#$51		; start timer B counting underflows
		sta	$dd0f		; of timer A
		rts
.endproc

; set the clock
; in:
;   A - seconds
;   X - minutes
;   Y - hours
; out:
;   <nothing>
.proc clock_set
		sta	sseconds	; set temporary values for clock
		stx	sminutes
		sty	shours
		inc	set		; set flag for setting clock
		rts
.endproc

; read the clock
; in:
;   <nothing>
; out:
;   A - seconds
;   X - minutes
;   Y - hours
.proc clock_get
		lda	seconds
		ldx	minutes
		ldy	hours
		sec
		rts
.endproc

; "drive" the clock, call this regularly, e.g. once per frame
; in:
;   <nothing>
; out:
;   if C = 1: clock advanced one second
;      A - new seconds
;      X - new minutes
;      Y - new hours
;   if C = 0: no change, no output
.proc clock_run
		lda	set		; check flag for setting the clock
		beq	noset		; not set -> continue
		lda	sseconds	; copy temporary values to real clock
		sta	seconds
		lda	sminutes
		sta	minutes
		lda	shours
		sta	hours
		lda	#$0		; clear flag for setting
		sta	set
		lda	#$80		; load "last" with something larger
		sta	last		; than any timer B value
		jsr	clock_init::starttimers	; restart the timers
		bne	clock_get	; return the newly set time

noset:		lda	$dd06		; load timer B value
		cmp	last		; compare with last one
		sta	last		; and remember it as the new "last"
		beq	done		; if equal or smaller, nothing happened
		bcc	done		; otherwise timer B had an underflow
		lda	$2a6		; check system flag for NTSC
		bne	nostall		; nothing to do on PAL

		; on NTSC, our timers count 6 cycles short. DEC and INC each
		; take 6 cycles, so their writes will happen exactly 6 cycles
		; apart from each other. Therefore, the following will stall
		; timer A for exactly 6 cycles and eliminate our "error" on
		; NTSC:
		dec	$dd0e
		inc	$dd0e

nostall:	ldx	seconds		; load current seconds
		inx			; increment
		stx	seconds		; and store
		cpx	#60		; reached 60?
		bcc	clock_get	; if not, return current clock
		ldx	#$0		; set seconds to 0
		stx	seconds
		ldx	minutes		; load current minutes
		inx			; increment
		stx	minutes		; and store
		cpx	#60		; reached 60?
		bcc	clock_get	; if not, return current clock
		ldx	#$0		; set minutes to 0
		stx	minutes
		ldx	hours		; load current hours
		inx			; increment
		cpx	#24		; reached 24?
		bcc	hoursok		; if not, skip resetting them
		ldx	#$0		; reset hours to 0
hoursok:	stx	hours		; and store
		bpl	clock_get	; go to returning current clock

done:		clc			; clear carry to signal "no change"
		rts			; and return
.endproc

