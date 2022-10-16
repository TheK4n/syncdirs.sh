DESTDIR :=
PREFIX := /usr/local
SCRIPTNAME = bkp.sh
BINARY = bkp
BASHCOMPDIR ?= $(PREFIX)/share/bash-completion/completions
ZSHCOMPDIR ?= $(PREFIX)/share/zsh/site-functions
MANDIR ?= $(PREFIX)/share/man

.PHONY: all install uninstall

all: install

install:
	install -Dm755 $(SCRIPTNAME) $(DESTDIR)$(PREFIX)/bin/$(BINARY)
	install -vd "$(DESTDIR)$(BASHCOMPDIR)" && install -m 0644 bkp.bash-completion "$(DESTDIR)$(BASHCOMPDIR)/bkp"
	install -vd "$(DESTDIR)$(ZSHCOMPDIR)" && install -m 0644 bkp.zsh-completion "$(DESTDIR)$(ZSHCOMPDIR)/_bkp"
	install -vd "$(DESTDIR)$(MANDIR)/man1" && install -m 0644 manpage "$(DESTDIR)$(MANDIR)/man1/bkp.1"

uninstall:
	rm "$(DESTDIR)$(PREFIX)/bin/$(BINARY)"
	rm "$(DESTDIR)$(BASHCOMPDIR)/bkp"
	rm "$(DESTDIR)$(ZSHCOMPDIR)/_bkp"
	rm "$(DESTDIR)$(MANDIR)/man1/bkp.1"
