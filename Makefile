PREFIX ?= /usr/local
BINARY = backdrop
BUILD_DIR = $(shell swift build --show-bin-path -c release 2>/dev/null || echo .build/release)

.PHONY: build install uninstall test clean

build:
	swift build --disable-sandbox -c release

install: build
	install -d $(PREFIX)/bin
	install $(BUILD_DIR)/$(BINARY) $(PREFIX)/bin/$(BINARY)

uninstall:
	rm -f $(PREFIX)/bin/$(BINARY)

test:
	swift test

clean:
	swift package clean
