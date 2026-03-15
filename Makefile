PREFIX ?= /usr/local
BINARY = backdrop
BUILD_DIR = $(shell swift build --show-bin-path -c release 2>/dev/null || echo .build/release)

.PHONY: build install uninstall test clean

build:
	swift build --disable-sandbox -c release

install: build
	install -d $(PREFIX)/bin
	install $(BUILD_DIR)/$(BINARY) $(PREFIX)/bin/$(BINARY)
	find $(BUILD_DIR) -name '*.bundle' -exec cp -R {} $(PREFIX)/bin/ \;

uninstall:
	rm -f $(PREFIX)/bin/$(BINARY)
	rm -rf $(PREFIX)/bin/backdrop_*.bundle
	-launchctl bootout gui/$$(id -u)/com.generald.backdrop 2>/dev/null
	rm -f $(HOME)/Library/LaunchAgents/com.generald.backdrop.plist

test:
	swift test

clean:
	swift package clean
