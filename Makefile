C64SYS?=c64
C64AS?=ca65
C64LD?=ld65
VICE?=x64sc
EXO?=exomizer

C64ASFLAGS?=-t $(C64SYS) -g

clock_LDCFG:=src/clock.cfg
clock_OBJS:=$(addprefix obj/,main.o clock.o)
clock_BIN:=clock.prg
clock_EXO:=clock.exo

borderclock_LDCFG:=src/borderclock.cfg
borderclock_OBJS:=$(addprefix obj/,load.o exodecrunch.o)
borderclock_BIN:=borderclock.prg

ifeq ($(DEFFONT),)
clock_OBJS+=obj/sprites.o
else
C64ASFLAGS+=-DDEFFONT
endif

all: $(borderclock_BIN)

run: all
	$(VICE) -autostart $(borderclock_BIN) -moncommands clock.lbl

$(clock_BIN): $(clock_OBJS)
	$(C64LD) -o$@ -Ln clock.lbl -m clock.map -C $(clock_LDCFG) $^

$(borderclock_BIN): $(borderclock_OBJS)
	$(C64LD) -o$@ -C $(borderclock_LDCFG) $^

%.exo: %.prg
	$(EXO) mem -l none -c -o$@ $<

obj:
	mkdir obj

obj/%.o: src/%.s src/clock.cfg Makefile | obj
	$(C64AS) $(C64ASFLAGS) -o$@ $<

obj/load.o: $(clock_EXO)

clean:
	rm -fr obj *.lbl *.map *.exo $(clock_BIN)

distclean: clean
	rm -f $(borderclock_BIN)

.PHONY: all run clean distclean

