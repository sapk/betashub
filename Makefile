##
# BetaShub Makefile
##

# Tools

INSTALL = install
LN_S    = ln -sf
RM      = rm -f

# Files

SRCS = src/betashub.sh
DOCS      = LICENCE INSTALL README

# Target path
# DESTDIR is for package creation only

PREFIX ?= /usr/local
BINDIR  = $(PREFIX)/bin
DATADIR = ${PREFIX}/share/betashub
DOCDIR  = ${PREFIX}/share/doc/betashub

# Packaging
GIT_DATE:=$(shell LANG=C git log -n1 --pretty=%ci | cut -d' ' -f1)
GIT_HASH:=$(shell LANG=C git log -n1 --pretty=%h)
DISTDIR = betashub-snapshot-git$(subst -,,$(GIT_DATE).$(GIT_HASH))

install:
	$(INSTALL) -d $(DESTDIR)$(BINDIR)
	$(INSTALL) -d $(DESTDIR)$(DATADIR)
	$(INSTALL) -d $(DESTDIR)$(DOCDIR)
	$(INSTALL) -m 755 $(SRCS) $(DESTDIR)$(DATADIR)
	$(INSTALL) -m 644 README $(DESTDIR)$(DOCDIR)
	$(LN_S) $(DATADIR)/betashub.sh $(DESTDIR)$(BINDIR)/betashub

uninstall:
	@$(RM) $(DESTDIR)$(BINDIR)/betashub
	@rm -rf $(DESTDIR)$(DATADIR) $(DESTDIR)$(DOCDIR)

dist: distdir
	@tar -cf - $(DISTDIR)/* | gzip -9 >$(DISTDIR).tar.gz
	@rm -rf $(DISTDIR)

distdir:
	@test -d $(DISTDIR) || mkdir $(DISTDIR)
	@mkdir -p $(DISTDIR)/src
	@for file in $(SRCS) $(DOCS); do \
		cp -pf $$file $(DISTDIR)/$$file; \
	done
	@for file in $(SRCS); do \
		sed -i 's/^VERSION=.*/VERSION='\''GIT-$(GIT_HASH) ($(GIT_DATE))'\''/' $(DISTDIR)/$$file; \
	done
	@for file in $(DOCS); do \
		sed -i '/[Pp]lowshare/s/\(.*\)GIT-snapshot\(.*\)/\1GIT-$(GIT_HASH) ($(GIT_DATE))\2/' $(DISTDIR)/$$file; \
	done

distclean:
	@rm -rf betashub-snapshot-*

.PHONY: dist distclean install uninstall
