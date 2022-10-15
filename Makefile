DESTDIR :=
PREFIX := /usr/local
SCRIPTNAME = bkp.sh
BINARY = bkp
BASHCOMPDIR ?= $(PREFIX)/share/bash-completion/completions
MANDIR ?= $(PREFIX)/share/man

.PHONY: all install uninstall

all: install

install:
	install -Dm755 $(SCRIPTNAME) $(DESTDIR)$(PREFIX)/bin/$(BINARY)
	install -vd "$(DESTDIR)$(BASHCOMPDIR)" && install -m 0644 bkp.bash-completion "$(DESTDIR)$(BASHCOMPDIR)/bkp"
	install -vd "$(DESTDIR)$(MANDIR)/man1" && install -m 0644 manpage "$(DESTDIR)$(MANDIR)/man1/bkp.1"

uninstall:
	rm "$(DESTDIR)$(PREFIX)/bin/$(BINARY)"
	rm "$(DESTDIR)$(BASHCOMPDIR)/bkp"
	rm "$(DESTDIR)$(MANDIR)/man1/bkp.1"
