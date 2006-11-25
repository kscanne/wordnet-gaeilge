# Not for distribution, only for use by the maintainer.
RELEASE=1.001
APPNAME=lionra-$(RELEASE)
TARFILE=$(APPNAME).tar
PDFNAME=lsg
BOOKNAME="Líonra Séimeantach Gaeilge"
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
webhome = $(HOME)/public_html/lsg
enirdir = $(HOME)/gaeilge/diolaim/c

all : $(PDFNAME).pdf thes_ga_IE_v2.zip

ga-data.noun ga-data.verb ga-data.adv ga-data.adj : wn2ga.txt
	LC_ALL=ga_IE perl enwn2gawn.pl

en2wn.pot : $(enirdir)/en
	perl en2wn.pl > $@

en2wn.po : en2wn.pot
	msgmerge -N -q --backup=off -U $@ en2wn.pot > /dev/null 2>&1
	touch $@

wn2ga.txt : en2wn.po $(HOME)/seal/ig7
	perl makewn2ga.pl > $@

th_ga_IE_v2.dat : ga-data.noun ga-data.verb ga-data.adv ga-data.adj
	LC_ALL=ga_IE perl gawn2ooo.pl -o

th_ga_IE_v2.idx : th_ga_IE_v2.dat
	cat th_ga_IE_v2.dat | perl th_gen_idx.pl > $@

README_th_ga_IE_v2.txt : README fdl.txt
	(echo; echo "1. Version"; echo; echo "This is version $(RELEASE) of $(BOOKNAME) for OpenOffice.org."; echo; echo "2. Copyright"; echo; cat README; echo; echo "3. Copying"; echo; cat fdl.txt) > $@

thes_ga_IE_v2.zip : th_ga_IE_v2.dat th_ga_IE_v2.idx README_th_ga_IE_v2.txt
	zip $@ th_ga_IE_v2.dat th_ga_IE_v2.idx README_th_ga_IE_v2.txt

$(PDFNAME).pdf : $(PDFNAME).tex brollach.tex sonrai.tex leabhair.bib nocites.tex
	sed -i "/Leagan anseo/s/^[0-9]*\.[0-9]*/$(RELEASE)/" $(PDFNAME).tex
	@touch $(PDFNAME).aux
	@cp $(PDFNAME).aux $(PDFNAME).aux.bak
	@$(PDFLATEX) -interaction=nonstopmode $(PDFNAME)
#	@if \
	     diff $(PDFNAME).aux $(PDFNAME).aux.bak > /dev/null ; \
	then \
	     echo 'Success.'; \
	else \
	     $(MAKE) bib; \
	fi
#	@rm $(PDFNAME).aux.bak

bib :
	@echo 'Rerunning BibTeX/LaTeX to fix bibliography...' 
	@$(BIBTEX) $(PDFNAME)
	@$(PDFLATEX) -interaction=nonstopmode $(PDFNAME)
	@echo 'LaTeX once more to correct cross references...'
	@$(PDFLATEX) -interaction=nonstopmode $(PDFNAME)

dist: $(PDFNAME).pdf
	ln -s teasaras ../$(APPNAME)
	tar cvhf $(TARFILE) -C .. $(APPNAME)/brollach.tex
	tar rvhf $(TARFILE) -C .. $(APPNAME)/fdl.tex
	tar rvhf $(TARFILE) -C .. $(APPNAME)/fncychap.sty
	tar rvhf $(TARFILE) -C .. $(APPNAME)/irish.dtx
	tar rvhf $(TARFILE) -C .. $(APPNAME)/nocites.tex
	tar rvhf $(TARFILE) -C .. $(APPNAME)/plainnatga.bst
	tar rvhf $(TARFILE) -C .. $(APPNAME)/README
	tar rvhf $(TARFILE) -C .. $(APPNAME)/sonrai.tex
	tar rvhf $(TARFILE) -C .. $(APPNAME)/$(PDFNAME).bbl
	tar rvhf $(TARFILE) -C .. $(APPNAME)/$(PDFNAME).tex
	gzip $(TARFILE)
	rm -f ../$(APPNAME)

map : FORCE
	perl mapper-ui.pl
	diff -u en2wn.po en2wn-new.po | more
	cpo -q en2wn.po
	cpo -q en2wn-new.po
	mv -f en2wn-new.po en2wn.po

leabhair.bib : $(leabharliostai)/IGbib
	@echo 'Rebuilding BibTeX database...'
	@$(GIN) 6

$(focloiri)/EN : $(focloiri)/IG
	@echo 'Generating English-Irish dictionary...'
	@$(GIN) 2

$(HOME)/seal/ig7 : $(focloiri)/IG
	(cd $(HOME)/seal; $(GIN) 17)

$(enirdir)/en : $(focloiri)/EN
	(cd $(enirdir); make)

sonrai.tex : ga-data.noun ga-data.verb ga-data.adv ga-data.adj
	LC_ALL=ga_IE perl gawn2ooo.pl -l

sonrai.txt : ga-data.noun ga-data.verb ga-data.adv ga-data.adj
	LC_ALL=ga_IE perl gawn2ooo.pl -t

installweb :
	$(INSTALL_DATA) index.html $(webhome)
	$(INSTALL_DATA) index-en.html $(webhome)
	$(INSTALL_DATA) sios.html $(webhome)

clean :
	rm -f en2wn.pot ga-data.noun ga-data.verb ga-data.adv ga-data.adj wn2ga.txt th_ga_IE_v2.dat th_ga_IE_v2.idx README_th_ga_IE_v2.txt thes_ga_IE_v2.zip leabhair.bib sonrai.tex sonrai.txt

texclean :
	rm -f $(PDFNAME).pdf $(PDFNAME).aux $(PDFNAME).dvi $(PDFNAME).log $(PDFNAME).out $(PDFNAME).ps $(PDFNAME).blg $(PDFNAME).aux.bak

distclean :
	$(MAKE) clean

maintainer-clean mclean :
	$(MAKE) distclean
	rm -f $(PDFNAME).bbl

FORCE:

.PRECIOUS : $(focloiri)/EN $(focloiri)/IG en2wn.po
