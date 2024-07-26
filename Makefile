SHELLCHECK ?= shellcheck
MKDIR ?= mkdir
RMRF ?= rm -rf
JSONSCHEMA ?= jsonschema

# Options
SCHEMAS ?= ./schemas
BASE_URL ?= https://schemas.intelligence.ai

.PHONY: all
all: lint prepare

build:
	$(MKDIR) $@
build/fetch: | build
	$(MKDIR) $@

.PHONY: prepare
prepare: collections | build/fetch
	./scripts/collections-fetch.sh $(realpath $<) $(realpath $|)
	./scripts/collections-install.sh $(realpath $<) $(realpath $|) $(realpath $(SCHEMAS))
	$(JSONSCHEMA) fmt --verbose $(realpath $(SCHEMAS))
	./scripts/generate-configuration.sh $(realpath $<) "$(BASE_URL)" > configuration.json

.PHONY: lint
lint:
	$(SHELLCHECK) scripts/*.sh
	$(JSONSCHEMA) fmt --verbose --check *.schema.json
	$(JSONSCHEMA) lint --verbose *.schema.json
	$(JSONSCHEMA) validate --verbose collection.schema.json collections/*/*.json
	$(JSONSCHEMA) validate --verbose namespace.schema.json collections/*.json

.PHONY: clean
clean:
	$(RMRF) build
