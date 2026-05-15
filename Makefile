APP_NAME := BMM
ARCHS ?= arm64 x86_64
ARCH_COUNT := $(words $(ARCHS))
BUNDLE := .build/release/$(APP_NAME).app
BINARY := .build/release/bmm
INSTALL_DIR ?= $(HOME)/Applications
INSTALL_BUNDLE := $(INSTALL_DIR)/$(APP_NAME).app
SIGN_IDENTITY ?= -

.PHONY: build app install clean run run-installed

build:
	rm -rf ".build/release"
	mkdir -p ".build/release"
	set -e; \
	built_binaries=""; \
	for arch in $(ARCHS); do \
		swift build -c release --arch "$$arch" --scratch-path ".build/$$arch"; \
		bin_path=$$(swift build -c release --arch "$$arch" --scratch-path ".build/$$arch" --show-bin-path); \
		cp "$$bin_path/bmm" ".build/release/bmm-$$arch"; \
		built_binaries="$$built_binaries .build/release/bmm-$$arch"; \
	done; \
	if [ "$(ARCH_COUNT)" -gt 1 ]; then \
		lipo -create $$built_binaries -output "$(BINARY)"; \
	else \
		cp $$built_binaries "$(BINARY)"; \
	fi

app: build
	rm -rf "$(BUNDLE)"
	mkdir -p "$(BUNDLE)/Contents/MacOS"
	mkdir -p "$(BUNDLE)/Contents/Resources"
	cp "$(BINARY)" "$(BUNDLE)/Contents/MacOS/$(APP_NAME)"
	cp Resources/Info.plist "$(BUNDLE)/Contents/Info.plist"
	cp Resources/AppIcon.icns "$(BUNDLE)/Contents/Resources/AppIcon.icns"
	cp Resources/*.png "$(BUNDLE)/Contents/Resources/"
	codesign --force --deep --sign "$(SIGN_IDENTITY)" "$(BUNDLE)"
	@echo "Built $(BUNDLE)"

install: app
	mkdir -p "$(INSTALL_DIR)"
	rm -rf "$(INSTALL_BUNDLE)"
	cp -R "$(BUNDLE)" "$(INSTALL_BUNDLE)"
	@echo "Installed $(INSTALL_BUNDLE)"

run:
	@test -d "$(BUNDLE)" || { echo "$(BUNDLE) does not exist. Run 'make app' first."; exit 1; }
	open "$(BUNDLE)"

run-installed:
	@test -d "$(INSTALL_BUNDLE)" || { echo "$(INSTALL_BUNDLE) does not exist. Run 'make install' first."; exit 1; }
	open "$(INSTALL_BUNDLE)"

clean:
	swift package clean
