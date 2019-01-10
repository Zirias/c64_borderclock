.import decrunch
.export get_crunched_byte

NEW		= $a644
STROUT		= $ab1e

.segment "BHDR"
		.word	$0801
		.word	$080b
		.word	2018
		.byte	$9e
sysaddr:
		.byte	"2061",$0,$0,$0

.code
		lda	#<decrmsg
		ldy	#>decrmsg
		jsr	STROUT
		jsr	decrunch
		jsr	$c2c0
		pla
		pla
		lda	#>(NEW-1)
		pha
		lda	#<(NEW-1)
		pha
		lda	#<message1
		ldy	#>message1
		jmp	STROUT

get_crunched_byte:
		lda	_byte_lo
		bne	_byte_skip_hi
		dec	_byte_hi
_byte_skip_hi:
		dec	_byte_lo
_byte_lo = * + 1
_byte_hi = * + 2
		lda	end_of_data
		rts

.data

decrmsg:	.byte	$d, "the annoying(ly exact) border clock", $d
		.byte	" *** released 1/2019 by zirias ***", $d, $d, $0
message1:	.byte	"command to set the clock:", $d, $d
		.byte	"  @t <hours>,<minutes>,<seconds>", $d, $d, $0

.incbin "clock.exo"
end_of_data:	.res	0

