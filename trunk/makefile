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
dechiall = $(freamh)/data/Ambiguities
webhome = $(HOME)/public_html/lsg    # change in README too
enirdir = $(HOME)/gaeilge/diolaim/c

all : $(PDFNAME).pdf thes_ga_IE_v2.zip englosses.txt

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

morcego.hash : ga-data.noun ga-data.verb ga-data.adv ga-data.adj
	LC_ALL=ga_IE perl gawn2ooo.pl -m

#  n.b. best to first make this target with "draft" mode on, then turn off
#  darft mode and try again.  This way the references will be in place and the
#  pdflatex bug will occur on the correct page number.   Insert any needed line
#  breaks and make once more.
# pdflatex until no "Rerun to get (citations|cross-references)"
$(PDFNAME).pdf : $(PDFNAME).tex brollach.tex $(PDFNAME).bbl
	sed -i "/Leagan anseo/s/^[0-9]*\.[0-9]*/$(RELEASE)/" $(PDFNAME).tex
	$(PDFLATEX) -interaction=nonstopmode $(PDFNAME)
	while ( grep "Rerun to get " $(PDFNAME).log >/dev/null ); do \
		$(PDFLATEX) -interaction=nonstopmode $(PDFNAME); \
	done

# multi-processor problem here - need to ensure that .bbl is newer than
# the .pdf which is output by first line
$(PDFNAME).bbl : leabhair.bib nocites.tex sonrai.tex
	$(PDFLATEX) -interaction=nonstopmode $(PDFNAME)
	sleep 5
	$(BIBTEX) $(PDFNAME)

# assuming irish.dtx (from babel package) is installed
# and also my gahyph.tex (not standardly distributed)
dist: $(PDFNAME).bbl
	ln -s teasaras ../$(APPNAME)
	tar cvhf $(TARFILE) -C .. $(APPNAME)/brollach.tex
	tar rvhf $(TARFILE) -C .. $(APPNAME)/fdl.tex
	tar rvhf $(TARFILE) -C .. $(APPNAME)/fncychap.sty
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

WORDNET=.
mac.zip : FORCE
	zip mac.zip $(WORDNET)/data.adj $(WORDNET)/data.adv $(WORDNET)/data.noun $(WORDNET)/data.verb $(WORDNET)/index.sense en2wn.po mapper-ui.pl en
	mv -f mac.zip $(HOME)/public_html/obair

leabhair.bib : $(leabharliostai)/IGbib
	@echo 'Rebuilding BibTeX database...'
	@$(GIN) 6

# Gin 2 uses the disambiguator to fill in "DUMMY" entries
$(focloiri)/EN : $(focloiri)/IG $(dechiall)/EN
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

englosses.txt : en2wn.po
	perl englosses.pl | sort -k1,1 > $@

print : FORCE
	$(MAKE) $(enirdir)/en
	(echo '<html><body>'; egrep -f current.txt $(enirdir)/en | sed 's/$$/<br>/'; echo '</body></html>') > $(HOME)/public_html/obair/print.html

commit : FORCE
	(COMSG="batch `(cat line.txt; echo '50 / p') | dc` done"; cvs commit -m "$$COMSG" en2wn.po)

installweb :
	$(INSTALL_DATA) index.html $(webhome)
	$(INSTALL_DATA) index-en.html $(webhome)
	$(INSTALL_DATA) sios.html $(webhome)

texclean :
	rm -f $(PDFNAME).pdf $(PDFNAME).aux $(PDFNAME).dvi $(PDFNAME).log $(PDFNAME).out $(PDFNAME).ps $(PDFNAME).blg

clean :
	$(MAKE) texclean
	rm -f en2wn.pot ga-data.noun ga-data.verb ga-data.adv ga-data.adj wn2ga.txt th_ga_IE_v2.dat th_ga_IE_v2.idx README_th_ga_IE_v2.txt thes_ga_IE_v2.zip sonrai.txt englosses.txt

distclean :
	$(MAKE) clean

maintainer-clean mclean :
	$(MAKE) distclean
	rm -f $(PDFNAME).bbl leabhair.bib sonrai.tex

FORCE:

.PRECIOUS : $(focloiri)/EN $(focloiri)/IG en2wn.po
