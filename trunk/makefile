RELEASE=1.0
APPNAME=teasaras-$(RELEASE)
TARFILE=$(APPNAME).tar
SHELL = /bin/sh
freamh = /mathhome/kps/math/code
leabharliostai = $(freamh)/data/Bibliography
focloiri = $(freamh)/data/Dictionary
teasarais = $(freamh)/data/Thesaurus
reitigh = $(freamh)/data/Ambiguities
sortailte = $(freamh)/data/Sorted_Thesaurus
tl.pdf : tl.tex brollach.tex sonrai.tex leabhair.bib
	@echo 'Generating PDF...' 
	@touch tl.aux
	@cp tl.aux tl.aux.bak
	@pdflatex -interaction=nonstopmode tl > /dev/null
	@if \
	     diff tl.aux tl.aux.bak > /dev/null ; \
	then \
	     echo 'Success.'; \
	else \
	     make bib; \
	fi
	@rm tl.aux.bak
bib :
	@echo 'Rebuilding bibliography...' 
	@bibtex tl > /dev/null
	@pdflatex -interaction=nonstopmode tl > /dev/null
	@echo 'Correcting cross references...'
	@pdflatex -interaction=nonstopmode tl > /dev/null
leabhair.bib : $(leabharliostai)/IGbib
	@echo 'Rebuilding BibTeX database...'
	@$(freamh)/main/Gin 6
sonrai.tex : $(sortailte)/IG
	@echo 'Generating LaTeX source...'
	@$(freamh)/main/Gin 5
$(sortailte)/IG : $(teasarais)/IG
	@echo 'Sorting thesaurus alphabetically...'
	@$(freamh)/main/Gin 4
$(teasarais)/IG : reitithe.0 $(focloiri)/EN
	@echo 'Translating thesaurus English->Irish...'
	@$(freamh)/main/Gin 3
$(focloiri)/EN : reitithe.1
	@echo 'Generating English-Irish dictionary...'
	@$(freamh)/main/Gin 2
reitithe.1 : $(focloiri)/IG $(reitigh)/EN
	@echo 'Checking for ambiguities in Irish-English dictionary...'
	@$(freamh)/main/Gin 1
	@touch reitithe.1
reitithe.0 : $(teasarais)/EN $(reitigh)/EN
	@echo 'Checking for ambiguities in English thesaurus...'
	@$(freamh)/main/Gin 0
	@touch reitithe.0
clean :
	rm -f tl.pdf tl.aux tl.dvi tl.log tl.out tl.ps sonrai.tex tl.bbl tl.blg leabhair.bib
tlclean :
	rm -f tl.pdf tl.aux tl.dvi tl.log tl.out tl.ps tl.bbl tl.blg
count : sonrai.tex
	grep "\-\-\-" sonrai.tex | wc -l
tarfile: tl.pdf
	ln -s teasaras ../$(APPNAME)
	tar cvhf $(TARFILE) -C .. $(APPNAME)/brollach.tex
	tar rvhf $(TARFILE) -C .. $(APPNAME)/fncychap.sty
	tar rvhf $(TARFILE) -C .. $(APPNAME)/irish.dtx
	tar rvhf $(TARFILE) -C .. $(APPNAME)/makefile
	tar rvhf $(TARFILE) -C .. $(APPNAME)/plainnatga.bst
	tar rvhf $(TARFILE) -C .. $(APPNAME)/sonrai.tex
	tar rvhf $(TARFILE) -C .. $(APPNAME)/tl.bbl
	tar rvhf $(TARFILE) -C .. $(APPNAME)/tl.tex
	gzip $(TARFILE)
	rm -f ../$(APPNAME)
FORCE :

.PRECIOUS : $(teasarais)/IG $(focloiri)/EN reitithe.0 reitithe.1
