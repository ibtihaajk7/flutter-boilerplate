# Every target is a thin wrapper, so CI and your machine run the same thing.
.DEFAULT_GOAL := help
.PHONY: help setup run check format format-check analyze l10n l10n-check test coverage fix hooks clean slim slim-markers rename

help: ## List commands
	@grep -E '^[a-z0-9-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  make %-14s %s\n", $$1, $$2}'

setup: ## First run: create .env, get packages, generate l10n
	@test -f .env || cp .env.example .env
	flutter pub get
	flutter gen-l10n

run: ## Run the app on the connected device
	flutter run

check: format-check analyze l10n-check coverage ## Everything CI checks

format: ## Format all Dart code
	dart format lib test tool

format-check:
	dart format --output=none --set-exit-if-changed lib test tool

analyze: ## Strict static analysis (infos fail too)
	flutter analyze --fatal-infos --fatal-warnings

l10n: ## Regenerate localizations after editing .arb files
	flutter gen-l10n

l10n-check: ## ARB files have the same keys and placeholders
	dart run tool/check_l10n.dart

test: ## Run all tests
	flutter test

coverage: ## Tests with the coverage gate (80% min, every lib file tested)
	flutter test --coverage
	dart run tool/check_coverage.dart --min 80

fix: ## Apply automated fixes, then format
	dart fix --apply
	dart format lib test tool

hooks: ## Run `make check` before every git push
	@printf '#!/bin/sh\nmake check\n' > .git/hooks/pre-push && chmod +x .git/hooks/pre-push
	@echo "pre-push hook installed"

slim: ## Remove optional modules: make slim WITHOUT=analytics,crash,notifications
	@test -n "$(WITHOUT)" || (echo "Usage: make slim WITHOUT=analytics,crash,notifications" && exit 64)
	dart run tool/slim.dart --without $(WITHOUT)

slim-markers: ## Keep every module, remove the slim marker comments
	dart run tool/slim.dart --strip-markers

clean: ## Remove build outputs
	flutter clean
	rm -rf coverage

# template:start
rename: ## Rename the template: make rename NAME=my_app ORG=com.acme DISPLAY="My App"
	@test -n "$(NAME)" -a -n "$(ORG)" || (echo "Usage: make rename NAME=my_app ORG=com.acme DISPLAY=\"My App\"" && exit 64)
	dart run tool/rename.dart --name $(NAME) --org $(ORG) $(if $(DISPLAY),--display "$(DISPLAY)")
	@$(MAKE) setup
# template:end
