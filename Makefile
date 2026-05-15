APP_NAME := BMM
ARCHS ?= arm64 x86_64
ARCH_COUNT := $(words $(ARCHS))
BUNDLE := .build/release/$(APP_NAME).app
BINARY := .build/release/bmm

.PHONY: build app clean run

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
	codesign --force --deep --sign - "$(BUNDLE)"
	@echo "Built $(BUNDLE)"

run: app
	open "$(BUNDLE)"

clean:
	swift package clean
