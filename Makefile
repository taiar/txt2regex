NAME = txt2regex
VERSION	= 0.6

SHSKEL = $(NAME)-$(VERSION).sh
DISTDIR = $(NAME)-$(VERSION)
PODIR = po
TESTDIR = test-suite

FILES = Makefile README NEWS Changelog COPYRIGHT TODO $(SHSKEL) $(PODIR) tools $(TESTDIR)


DESTDIR = 
BINDIR	= $(DESTDIR)/usr/bin
LOCALEDIR = $(DESTDIR)/usr/share/locale

TARGET=all

clean:
	rm -f {,po/}messages po/*.{mo,old,tmp,bk} test-suite/javascript.html $(NAME)
	find po -mindepth 1 -type d -exec rm -rf {} \;

check-po-dir: 
	@if [ ! -d $(PODIR) ]; then \
	echo "warning: directory '$(PODIR)' not found. nothing to do."; \
	exit 1;\
	fi

# shit, bash <<-HEREDOC seems to doesn't work inside Makefile...
pot: check-po-dir
	@cd $(PODIR); \
	DATE=`date '+%Y-%m-%d %H:%M %Z'`;\
	echo '#, fuzzy'                                          > $(NAME).pot.tmp;\
	echo 'msgid ""'                                         >> $(NAME).pot.tmp;\
	echo 'msgstr ""'                                        >> $(NAME).pot.tmp;\
	echo '"Project-Id-Version: $(NAME) $(VERSION)\n"'       >> $(NAME).pot.tmp;\
	echo "\"POT-Creation-Date: $$DATE\n\""                  >> $(NAME).pot.tmp;\
	echo '"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\n"'      >> $(NAME).pot.tmp;\
	echo '"Last-Translator: FULL NAME <EMAIL@ADDRESS>\n"'   >> $(NAME).pot.tmp;\
	echo '"Language-Team: LANGUAGE <LL@li.org>\n"'          >> $(NAME).pot.tmp;\
	echo '"MIME-Version: 1.0\n"'                            >> $(NAME).pot.tmp;\
	echo '"Content-Type: text/plain; charset=iso-8859-1\n"' >> $(NAME).pot.tmp;\
	echo '"Content-Transfer-Encoding: 8bit\n"'              >> $(NAME).pot.tmp;\
	bash --dump-po-strings ../$(SHSKEL)                     >> $(NAME).pot.tmp;\
	../tools/bashdump-rmdup.sh $(NAME).pot.tmp               > $(NAME).pot;\
	grep '##duplicated##'                                      $(NAME).pot;

po: check-po-dir
	@cd $(PODIR) && \
	for pot in *.po; do \
		echo -n "merging $$pot..."; \
		poti=`echo $$pot | sed 's/\.po$$//'`; \
		cp $$pot $$pot.old && \
		msgmerge $$pot.old $(NAME).pot > $$pot; \
	done

mo: check-po-dir
	@cd $(PODIR) && \
	for pot in *.po; do \
		echo -n "compiling $$pot..."; \
		poti=`echo $$pot | sed 's/\.po$$//'`; \
		msgfmt -o $$poti.mo $$pot && \
		echo ok; \
	done

check-po: check-po-dir
	@cd $(PODIR) && \
	for pot in *.po; do \
		echo -n "checking $$pot... "; \
		msgfmt -v $$pot || exit 1; \
	done

update-po: pot po mo


tgz: clean #check-po
	mkdir $(DISTDIR) && \
	cp -a $(FILES) $(DISTDIR) && \
	tar cvzf $(DISTDIR).tgz $(DISTDIR) && \
	rm -rf $(DISTDIR)

# just once: COPYRIGHT tools linuxformat.png old screenshot.png
upload:
	scp -r `echo $(FILES) | sed 's/COPYRIGHT\|tools\|test-suite//g'` index.html $(DISTDIR).tgz \
	  verde666@$(NAME).sf.net:/home/groups/t/tx/$(NAME)/htdocs
    
install: mo
	@[ -d $(LOCALEDIR) ] || mkdir -p $(LOCALEDIR); \
	for pot in `cd $(PODIR) && ls *.mo`; do \
		poti=`echo $$pot | sed 's/\.mo$$//'`; \
		modir=$(LOCALEDIR)/$$poti/LC_MESSAGES; \
		[ -d $$modir ] || mkdir -p $$modir; \
		install -m644 $(PODIR)/$$pot $$modir/$(NAME).mo; \
	done; \
	sed 's,^\(TEXTDOMAINDIR=\).*,\1$(LOCALEDIR),' $(SHSKEL) > $(BINDIR)/$(NAME) && \
	chmod +x $(BINDIR)/$(NAME) && \
	echo "program '$(NAME)' installed. just run $(BINDIR)/$(NAME)"