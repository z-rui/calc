CC=gcc
CFLAGS=-Wall -ggdb3
CFLAGS+=-DNDEBUG -O3 -fwhole-program

TEX=tex
CHANGE=-

all: calc calc.pdf 

calc: calc.o
	$(CC) -o $@ $(LDFLAGS) $^ $(LIBS)

%.o: %.c
	$(CC) -c -o $@ $(CFLAGS) $<

%.c: %.w $(CHANGE)
	ctangle $< $(CHANGE) $@

%.tex: %.w $(CHANGE)
	cweave $< $(CHANGE) $@

%.dvi: %.tex
	$(TEX) "\let\pdf+\input $<"

calc.pdf: calc.dvi calc.1
	dvipdfm $<

calc.1: calc.mp
	mpost $<

clean:
	rm -f calc.{o,c,tex,dvi,idx,scn,toc,log}

.PHONY: all clean
