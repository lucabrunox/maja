VALAC = valac
SRCS = main.vala jscodegen.vala jscode.vala jswriter.vala
PREFIX = /usr/local
DESTDIR = $(PREFIX)

all: majac

majac: $(SRCS)
	$(VALAC) -g -o majac --thread --pkg libvala-0.12 --pkg gee-1.0 $+

install: majac
	install -c ./majac -D $(DESTDIR)/bin/majac

clean:
	rm -f majac *.c
