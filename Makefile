# Build and install ocelado-hello.
#   make && sudo make install
#   make install DESTDIR=%{buildroot} PREFIX=/usr     (packaging)

PREFIX ?= /usr
LIBEXECDIR ?= $(PREFIX)/libexec
DATADIR ?= $(PREFIX)/share
SYSCONFDIR ?= /etc
CARGO ?= cargo
CARGOFLAGS ?= --release
QMAKE ?= $(shell command -v qmake6 || command -v qmake-qt6 || echo qmake6)

BIN = target/release/ocelado-hello

all: $(BIN)

$(BIN):
	QMAKE=$(QMAKE) $(CARGO) build $(CARGOFLAGS)

test:
	QMAKE=$(QMAKE) $(CARGO) test

install: $(BIN)
	install -Dm0755 $(BIN) $(DESTDIR)$(PREFIX)/bin/ocelado-hello
	install -Dm0755 data/ocelado-hello-helper $(DESTDIR)$(LIBEXECDIR)/ocelado-hello/ocelado-hello-helper
	install -Dm0755 data/ocelado-hello-query $(DESTDIR)$(LIBEXECDIR)/ocelado-hello/ocelado-hello-query
	install -Dm0644 data/org.ocelado.hello.policy $(DESTDIR)$(DATADIR)/polkit-1/actions/org.ocelado.hello.policy
	install -Dm0644 data/ocelado-hello.desktop $(DESTDIR)$(DATADIR)/applications/ocelado-hello.desktop
	install -Dm0644 data/ocelado-hello-autostart.desktop $(DESTDIR)$(SYSCONFDIR)/xdg/autostart/ocelado-hello.desktop

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/ocelado-hello
	rm -rf $(DESTDIR)$(LIBEXECDIR)/ocelado-hello
	rm -f $(DESTDIR)$(DATADIR)/polkit-1/actions/org.ocelado.hello.policy
	rm -f $(DESTDIR)$(DATADIR)/applications/ocelado-hello.desktop
	rm -f $(DESTDIR)$(SYSCONFDIR)/xdg/autostart/ocelado-hello.desktop

clean:
	$(CARGO) clean

.PHONY: all test install uninstall clean
