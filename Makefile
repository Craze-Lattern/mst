#!/usr/bin/scrun make -f

TEMPORARY_FOLDER?=/tmp/mst.dst
PREFIX?=/usr/local
BUILD_TOOL?=xcodebuild

SWIFT_BUILD_FLAGS=--configuration release
UNAME=$(shell uname)
ifeq ($(UNAME), Darwin)
USE_SWIFT_STATIC_STDLIB:=$(shell test -d $$(dirname $$(xcrun --find swift))/../lib/swift_static/macosx && echo yes)
ifeq ($(USE_SWIFT_STATIC_STDLIB), yes)
SWIFT_BUILD_FLAGS+= -Xswiftc -static-stdlib
endif
endif

MST_EXECUTABLE=$(shell swift build $(SWIFT_BUILD_FLAGS) --show-bin-path)/mst

FRAMEWORKS_FOLDER=/Library/Frameworks
BINARIES_FOLDER=/usr/local/bin

OUTPUT_PACKAGE=Mst.pkg

MST_PLIST=Sources/mst/Supporting Files/Info.plist
MSTKIT_PLIST=Sources/MstKit/Supporting Files/Info.plist

VERSION_STRING=$(shell /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$(MST_PLIST)")

.PHONY: all bootstrap hooks clean build install package uninstall xcodeproj sort release

all: build

bootstrap: hooks sort
	brew bundle install --verbose
	carthage bootstrap --platform macOS --cache-builds

hooks = $(addprefix .git/,$(wildcard hooks/*))
$(hooks):
	@test -d .git/hooks && ln -fnsv $(patsubst .git/%,$(PWD)/%,$@) $@ \
		|| echo "skipping git hook installation: .git/hooks does not exist" >&2 1>/dev/null

hooks: $(hooks)

clean:
	rm -f "$(OUTPUT_PACKAGE)"
	rm -rf "$(TEMPORARY_FOLDER)"
	swift package clean

build:
	swift build $(SWIFT_BUILD_FLAGS)

build_with_disable_sandbox:
	swift build --disable-sandbox $(SWIFT_BUILD_FLAGS)

install: build
	install -d "$(BINARIES_FOLDER)"
	install "$(MST_EXECUTABLE)" "$(BINARIES_FOLDER)"

uninstall:
	rm -rf "$(FRAMEWORKS_FOLDER)/MstKit.framework"
	rm -f "$(BINARIES_FOLDER)/mst"

installables: build
	install -d "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)"
	install "$(MST_EXECUTABLE)" "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)"

prefix_install: build_with_disable_sandbox
	install -d "$(PREFIX)/bin/"
	install "$(MST_EXECUTABLE)" "$(PREFIX)/bin/"

package: installables
	pkgbuild \
		--identifier "com.gy.mst" \
		--install-location "/" \
		--root "$(TEMPORARY_FOLDER)" \
		--version "$(VERSION_STRING)" \
		"$(OUTPUT_PACKAGE)"

archive:
	carthage build --no-skip-current --platform mac
	carthage archive MstKit

xcodeproj:
	swift package generate-xcodeproj

sort:
	perl script/sort.pl mst-cli.xcodeproj/project.pbxproj

get_version:
	@echo $(VERSION_STRING)

release:
ifneq ($(strip $(shell git status --untracked-files=no --porcelain 2>/dev/null)),)
	$(error git state is not clean)
endif
	$(eval NEW_VERSION_AND_NAME := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval NEW_VERSION := $(shell echo $(NEW_VERSION_AND_NAME) | sed 's/:.*//' ))
	@sed 's/__VERSION__/$(NEW_VERSION)/g' script/Version.swift.template > Sources/MstKit/Models/Version.swift
	@/usr/bin/agvtool new-marketing-version "$(NEW_VERSION)"
	@/usr/bin/agvtool next-version -all
	git commit -a -m "Release $(NEW_VERSION)"
	git tag -a $(NEW_VERSION) -m "$(NEW_VERSION_AND_NAME)"
	git push origin master

%:
	@:
