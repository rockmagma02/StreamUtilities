print-%: ; @echo $* = $($*)
PROJECT_NAME   = StreamUtilities
COPYRIGHT      = "Ruiyang Sun. All Rights Reserved."
SOURCE_FOLDERS = Sources Tests
SHELL          = /bin/bash

HOME		   = $(shell echo $$HOME)
SWIFT_VERSION  = system
SWIFT_TRUE_VERSION = 5.10


# Swift Installation
install-brew:
	$(SHELL) -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

install-swiftenv:
	brew install kylef/formulae/swiftenv

install-Swift:
	if command -v swiftenv >/dev/null; then \
		swiftenv install $(SWIFT_VERSION); \
	else \
		echo "swiftenv not found"; \
		echo "install swiftenv by brew first"; \
		if command -v brew >/dev/null; then \
			make install-swiftenv; \
		else \
			echo "brew not found"; \
			echo "install brew first"; \
			make install-brew; \
			make install-swiftenv; \
		fi; \
		swiftenv install $(SWIFT_VERSION); \
	fi

# Init Swift Environment
init-swift:
	if command -v swiftenv >/dev/null; then \
		swiftenv local $(SWIFT_VERSION); \
	else \
		make install-Swift; \
		make init-swift; \
	fi

# Build
build: init-swift
	swift build

build-verbose: init-swift
	swift build --vv

# Test
test: build
	swift test

# Clean
clean: init-swift
	swift package clean

clean-dist:
	rm -rf .build
	make clean

# Documentation

doc: init-swift
	swift package --allow-writing-to-directory ./Documentation generate-documentation-multitarget --main-target $(PROJECT_NAME) --target SyncStream --target BidirectionalStream --output ./Documentation

# Tools Installation
pre-commit-install:
	if ! command -v pre-commit >/dev/null; then \
		if ! command -v brew >/dev/null; then \
			echo "brew not found"; \
			echo "install brew first"; \
			make install-brew; \
		fi; \
		brew install pre-commit; \
	fi

swiftlint-install:
	if ! command -v swiftlint >/dev/null; then \
		if ! command -v brew >/dev/null; then \
			echo "brew not found"; \
			echo "install brew first"; \
			make install-brew; \
		fi; \
		brew install swiftlint; \
	fi

go-install:
	# requires go >= 1.16
	if ! command -v go >/dev/null; then \
		if ! command -v brew >/dev/null; then \
			echo "brew not found"; \
			echo "install brew first"; \
			make install-brew; \
		fi; \
		brew install go; \
	fi

swiftformat-install:
	if ! command -v swiftformat >/dev/null; then \
		if ! command -v brew >/dev/null; then \
			echo "brew not found"; \
			echo "install brew first"; \
			make install-brew; \
		fi; \
		brew install swiftformat; \
	fi

addlicense-install: go-install
	command -v $(HOME)/go/bin/addlicense || go install github.com/google/addlicense@latest

# Tools
pre-commit: pre-commit-install
	pre-commit --version
	pre-commit run --all-files

swiftlint: swiftlint-install
	swiftlint --version
	swiftlint --fix --config .swiftlint.yaml

swiftformat: swiftformat-install
	swiftformat --version
	swiftformat . --verbose

addlicense: addlicense-install
	$(HOME)/go/bin/addlicense -c $(COPYRIGHT) -l apache -y 2024-$(shell date +"%Y") $(SOURCE_FOLDERS)
	$(HOME)/go/bin/addlicense -c $(COPYRIGHT) -l apache -y 2024-$(shell date +"%Y") -c $(SOURCE_FOLDERS)
