## Makefile for An Teasáras Leictreonach.  Not for distribution,
## only for use by the maintainer.
RELEASE=0.01
APPNAME=teasaras-$(RELEASE)
TARFILE=$(APPNAME).tar
SHELL = /bin/sh
TETEXBIN = /usr/bin
PDFLATEX = $(TETEXBIN)/pdflatex
BIBTEX = $(TETEXBIN)/bibtex
MAKE = /usr/bin/make
GIN = $(HOME)/clar/denartha/Gin
INSTALL = /usr/bin/install
INSTALL_DATA = $(INSTALL) -m 444
freamh = $(HOME)/math/code
leabharliostai = $(freamh)/data/Bibliography
focloiri = $(freamh)/data/Dictionary
webhome = $(HOME)/public_html/teasaras
enirdir = $(HOME)/gaeilge/diolaim/c

all : thes_ga_IE_v2.zip

ga-data.noun ga-data.verb ga-data.adv ga-data.adj : wn2ga.txt
	perl enwn2gawn.pl

en2wn.pot : $(enirdir)/en
	perl en2wn.pl > $@

en2wn.po : en2wn.pot
	msgmerge -N -q --backup=off -U $@ en2wn.pot > /dev/null 2>&1
	touch $@

wn2ga.txt : en2wn.po /home/kps/seal/ig7
	perl makewn2ga.pl > $@

th_ga_IE_v2.dat : ga-data.noun ga-data.verb ga-data.adv ga-data.adj
	perl gawn2ooo.pl

th_ga_IE_v2.idx : th_ga_IE_v2.dat
	cat th_ga_IE_v2.dat | perl th_gen_idx.pl > $@

README_th_ga_IE_v2.txt : README fdl.txt
	(echo; echo "1. Version"; echo; echo "This is version $(RELEASE) of An Teasáras Leictreonach for OpenOffice.org."; echo; echo "2. Copyright"; echo; cat README; echo; echo "3. Copying"; echo; cat fdl.txt) > $@

thes_ga_IE_v2.zip : th_ga_IE_v2.dat th_ga_IE_v2.idx README_th_ga_IE_v2.txt
	zip $@ th_ga_IE_v2.dat th_ga_IE_v2.idx README_th_ga_IE_v2.txt

map : FORCE
	cp -f en2wn.po en2wn.po.bak
	perl mapper-ui.pl
	diff -u en2wn.po en2wn-new.po | more
	cpo -q en2wn.po
	cpo -q en2wn-new.po
	mv -f en2wn-new.po en2wn.po

leabhair.bib : $(leabharliostai)/IGbib
	@echo 'Rebuilding BibTeX database...'
	@$(GIN) 6

nocites.tex : $(leabharliostai)/IGbib
	@echo 'Rebuilding list of nocites...'
	@$(GIN) 14

$(focloiri)/EN : $(focloiri)/IG
	@echo 'Generating English-Irish dictionary...'
	@$(GIN) 2

$(enirdir)/en : $(focloiri)/EN
	(cd $(enirdir); make)

sonrai.tex : ga-data.noun ga-data.verb ga-data.adv ga-data.adj
	echo "to do"

installweb :
	$(INSTALL_DATA) index.html $(webhome)
	$(INSTALL_DATA) index-en.html $(webhome)
	$(INSTALL_DATA) sios.html $(webhome)

clean :
	rm -f en2wn.po.bak en2wn.pot ga-data.noun ga-data.verb ga-data.adv ga-data.adj wn2ga.txt th_ga_IE_v2.dat th_ga_IE_v2.idx README_th_ga_IE_v2.txt thes_ga_IE_v2.zip leabhair.bib nocites.tex sonrai.tex

distclean :
	$(MAKE) clean

maintainer-clean mclean :
	$(MAKE) distclean

FORCE:

.PRECIOUS : $(focloiri)/EN $(focloiri)/IG en2wn.po
