all: install

install:
	ln -s $(PWD)/bkp.sh ~/.local/bin/bkp

man:
	gzip -c manpage > /usr/local/man/man1/bkp.1