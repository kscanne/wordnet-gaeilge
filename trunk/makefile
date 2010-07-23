# Not for distribution, only for use by the maintainer.
RELEASE=1.001
APPNAME=lsg-latex-$(RELEASE)
TARFILE=$(APPNAME).tar
PDFNAME=lsg
BOOKNAME="Líonra Séimeantach na Gaeilge"
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

# not thesaurus zip file here; see groom
all : $(PDFNAME).pdf englosses.txt

ga-data.noun ga-data.verb ga-data.adv ga-data.adj : wn2ga.txt
	perl enwn2gawn.pl

en2wn.pot : $(enirdir)/en
	perl en2wn.pl > $@

en2wn.po : en2wn.pot
	msgmerge -N -q --backup=off -U $@ en2wn.pot > /dev/null 2>&1
	touch $@

wn2ga.txt : en2wn.po $(HOME)/seal/ig7
	perl makewn2ga.pl -y > $@

unmapped-irish.txt : en2wn.po $(HOME)/seal/ig7
	touch $@
	cp -f $@ unmapped-irish-prev.txt
	perl makewn2ga.pl -n > $@
	diff -u unmapped-irish-prev.txt $@ | more
	rm -f unmapped-irish-prev.txt

unmapped-problems.txt : unmapped-irish.txt
	cat unmapped-irish.txt | LC_ALL=C sed 's/^[^:]*: //' | tr "," "\n" | LC_ALL=C sort | uniq -c | sort -r -n > $@

# assumes aspell built for word list, gramadoir built for tags,
# stemmer built in ga2gd for stems...
# Used to create OOo thesaurus - see gawn2ooo.pl
stemmer.txt : FORCE
	cat ${HOME}/gaeilge/ispell/ispell-gaeilge/aspelllit.txt | alltagsep > tagged.txt
	cat tagged.txt | stemmer-ga -t > stems.txt
	paste tagged.txt stems.txt | tr "\t" "~" | tr "[:upper:]" "[:lower:]" | sed 's/<[^>]*>//g' | LC_ALL=C sort -u | egrep -v '^([^~]+)~\1$$' > $@
	rm -f stems.txt tagged.txt

th_ga_IE_v2.dat : ga-data.noun ga-data.verb ga-data.adv ga-data.adj stemmer.txt
	perl gawn2ooo.pl -o

th_ga_IE_v2.idx : th_ga_IE_v2.dat
	cat th_ga_IE_v2.dat | perl th_gen_idx.pl > $@

README_th_ga_IE_v2.txt : README fdl.txt
	(echo; echo "1. Version"; echo; echo "This is version $(RELEASE) of $(BOOKNAME) for OpenOffice.org."; echo; echo "2. Copyright"; echo; cat README; echo; echo "3. Copying"; echo; cat fdl.txt) > $@

ooo thes_ga_IE_v2.zip : th_ga_IE_v2.dat th_ga_IE_v2.idx README_th_ga_IE_v2.txt
	zip thes_ga_IE_v2.zip th_ga_IE_v2.dat th_ga_IE_v2.idx README_th_ga_IE_v2.txt

# compare fgbproc makefile; used for Wales talk
sensecounts.txt :
	cat th_ga_IE_v2.dat | LC_ALL=C sed '1d; s/^[^(]/!&/' | LC_ALL=C sed 's/|.*/|/' | tr -d "\n" | sed 's/|!/|\n/g' | sed 's/(infhillte)|//g' | egrep '\|\(' | sed 's/[0-9])/)/g' | sed 's/([bf])/(n)/g' | sed 's/(aid)/(a)/g' | sed 's/(af)/(n)/g' | sed 's/(iol)/(n)/g' | while read x; do echo "$$x" | egrep -o '\([^)]+\)' | sort | uniq -c | sort -r -n; done > $@

sensedist.txt :
	echo "ALL" > $@
	cat sensecounts.txt | sed 's/^ *//' | sed 's/ .*//' | sort | uniq -c | sort -r -n >> $@
	(echo; echo "NOUNS") >> $@
	cat sensecounts.txt | egrep ' \(n\)$$' | sed 's/^ *//' | sed 's/ .*//' | sort | uniq -c | sort -r -n >> $@
	(echo; echo "ADJECTIVES") >> $@
	cat sensecounts.txt | egrep ' \(a\)$$' | sed 's/^ *//' | sed 's/ .*//' | sort | uniq -c | sort -r -n >> $@
	(echo; echo "VERBS") >> $@
	cat sensecounts.txt | egrep ' \(br\)$$' | sed 's/^ *//' | sed 's/ .*//' | sort | uniq -c | sort -r -n >> $@
	(echo; echo "ADVERBS") >> $@
	cat sensecounts.txt | egrep ' \(db\)$$' | sed 's/^ *//' | sed 's/ .*//' | sort | uniq -c | sort -r -n >> $@

lsg.dot : ga-data.noun ga-data.verb ga-data.adv ga-data.adj
	perl gawn2ooo.pl -g

lsg.png : lsg.dot
	neato -Gsize="36,36" -Nshape="point" -Tpng -o $@ lsg.dot
#	neato -Gsize="8,8" -Tpng -o $@ lsg.dot

morcego.hash : ga-data.noun ga-data.verb ga-data.adv ga-data.adj
	perl gawn2ooo.pl -m

ambword.txt unambword.txt : ga-data.noun ga-data.verb ga-data.adv ga-data.adj
	egrep -h -o ' [^ ]+\+[0-9]+\+[^+]+\+[^ ]+' ga-data.* | sed 's/^ //; s/+[0-9]*+/+/; s/+[^ +]*$$//' | sed 's/+/ /' | LC_ALL=C sort -k1,1 | uniq > ambtemp.txt
	cat ambtemp.txt | sed 's/ .*//' | LC_ALL=C sort | uniq -c | egrep -v ' 1 ' | sed 's/^ *[0-9]* //' > ambtemp2.txt
	cat ambtemp.txt | sed 's/ .*//' | LC_ALL=C sort | uniq -c | egrep ' 1 ' | sed 's/^ *1 //' > ambtemp3.txt
	LC_ALL=C join ambtemp.txt ambtemp2.txt | sed 's/ /+/' | ./fixpos > ambword.txt
	LC_ALL=C join ambtemp.txt ambtemp3.txt | sed 's/ /+/' | ./fixpos > unambword.txt
	rm -f ambtemp.txt ambtemp2.txt ambtemp3.txt

lsgd.zip : unambword.txt morcego.hash deamh mydaemon.pl
	rm -Rf lsgd
	mkdir lsgd
	cp unambword.txt lsgd
	cp morcego.hash lsgd
	cp deamh lsgd
	touch lsgd/lsgd.log
	cp mydaemon.pl lsgd/lsgd.pl
	zip -r $@ lsgd
	rm -Rf lsgd

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
	perl mapper-ui.pl -p
	diff -u en2wn.po en2wn-new.po | more
	cpo -q en2wn.po
	cpo -q en2wn-new.po
	mv -f en2wn-new.po en2wn.po

mapn : FORCE
	perl mapper-ui.pl -n
	diff -u en2wn.po en2wn-new.po | more
	cpo -q en2wn.po
	cpo -q en2wn-new.po
	mv -f en2wn-new.po en2wn.po

unambig-data.noun : $(enirdir)/en
	LC_ALL=C egrep '^[^:]*  v' $(enirdir)/en | LC_ALL=C sed 's/  v.*//' | sort -u | tr ' ' '_' > ig.verb
	LC_ALL=C egrep '^[^:]*  a[^d]' $(enirdir)/en | LC_ALL=C sed 's/  a.*//' | sort -u | tr ' ' '_' > ig.adj
	LC_ALL=C egrep '^[^:]*  n' $(enirdir)/en | LC_ALL=C sed 's/  n.*//' | sort -u | tr ' ' '_' > ig.noun
	LC_ALL=C egrep '^[^:]*  adv' $(enirdir)/en | LC_ALL=C sed 's/  adv.*//' | sort -u | tr ' ' '_' > ig.adv
	perl unambig-finder.pl
	sort unambig-data.noun > tempfile
	mv tempfile unambig-data.noun
	sort unambig-data.verb > tempfile
	mv tempfile unambig-data.verb
	sort unambig-data.adj > tempfile
	mv tempfile unambig-data.adj
	sort unambig-data.adv > tempfile
	mv tempfile unambig-data.adv
	rm -f ig.verb ig.noun ig.adj ig.adv
	
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
	(cd $(HOME)/seal; $(GIN) 17; utf ig7)

$(enirdir)/en : $(focloiri)/EN
	(cd $(enirdir); make en)

sonrai.tex : ga-data.noun ga-data.verb ga-data.adv ga-data.adj
	perl gawn2ooo.pl -l

sonrai.txt : ga-data.noun ga-data.verb ga-data.adv ga-data.adj
	perl gawn2ooo.pl -t

englosses.txt : en2wn.po
	perl englosses.pl | sort -k1,1 > $@

print : FORCE
	$(MAKE) $(enirdir)/en
	(echo '<html><body>'; egrep -f current.txt $(enirdir)/en | sed 's/$$/<br>/'; echo '</body></html>') > $(HOME)/public_html/obair/print.html

commit : FORCE
	(COMSG="pass 3, batch `(cat line.txt; echo '100 / p') | dc` done"; cvs commit -m "$$COMSG" en2wn.po)

installweb :
	$(MAKE) installhtml
	$(MAKE) dist
	$(INSTALL_DATA) $(TARFILE).gz $(webhome)

installhtml :
	cp -f index.html temp.html
	sed -i "s/-1\.001\./-$(RELEASE)./" index.html
	$(INSTALL_DATA) index.html $(webhome)
	mv -f temp.html index.html
	cp -f index-en.html temp-en.html
	sed -i "s/-1\.001\./-$(RELEASE)./" index-en.html
	$(INSTALL_DATA) index-en.html $(webhome)
	mv -f temp-en.html index-en.html
	$(INSTALL_DATA) thanks.html $(webhome)
	$(INSTALL_DATA) thanks-en.html $(webhome)
	$(INSTALL_DATA) details.html $(webhome)
	$(INSTALL_DATA) details-en.html $(webhome)
	$(INSTALL_DATA) mcskps.jpg $(webhome)
	$(INSTALL_DATA) lsg-thumb.png $(webhome)
	$(INSTALL_DATA) lsg-best.png $(webhome)
	$(INSTALL_DATA) brothall.png $(webhome)
	$(INSTALL_DATA) lagachar.png $(webhome)
	$(INSTALL_DATA) meirbhe.png $(webhome)
	$(INSTALL_DATA) ooo.png $(webhome)

texclean :
	rm -f $(PDFNAME).pdf $(PDFNAME).aux $(PDFNAME).dvi $(PDFNAME).log $(PDFNAME).out $(PDFNAME).ps $(PDFNAME).blg

clean :
	$(MAKE) texclean
	rm -f en2wn.pot ga-data.noun ga-data.verb ga-data.adv ga-data.adj wn2ga.txt th_ga_IE_v2.dat th_ga_IE_v2.idx README_th_ga_IE_v2.txt thes_ga_IE_v2.zip sonrai.txt englosses.txt lsg.dot lsg.png morcego.hash ambword.txt unambword.txt unambig-data.* unmapped-irish.txt unmapped-problems.txt stemmer.txt lsg-latex-*.tar.gz sensecounts.txt sensedist.txt

distclean :
	$(MAKE) clean current.txt line.txt

maintainer-clean mclean :
	$(MAKE) distclean
	rm -f $(PDFNAME).bbl leabhair.bib sonrai.tex

FORCE:

.PRECIOUS : $(focloiri)/EN $(focloiri)/IG en2wn.po
