SHELLCHECK ?= shellcheck
MKDIR ?= mkdir
RMRF ?= rm -rf
JSONSCHEMA ?= jsonschema

# Options
CACHE ?= ./misc/cache
BASE_URL ?= https://schemas.intelligence.ai

.PHONY: all
all: lint prepare

build:
	$(MKDIR) $@
build/fetch: | build
	$(MKDIR) $@

.PHONY: prepare
prepare: collections | build/fetch
	./misc/collections-fetch.sh $(realpath $<) $(realpath $|) $(realpath $(CACHE))/schemas
	./misc/collections-install.sh $(realpath $<) $(realpath $|) $(realpath $(CACHE))/schemas
	$(JSONSCHEMA) fmt --verbose $(realpath $(CACHE))/schemas
	./misc/generate-configuration.sh $(realpath $<) "$(BASE_URL)" > $(realpath $(CACHE))/configuration.json

.PHONY: lint
lint:
	$(SHELLCHECK) misc/*.sh
	$(JSONSCHEMA) fmt --verbose --check misc/*.schema.json
	$(JSONSCHEMA) lint --verbose misc/*.schema.json
	$(JSONSCHEMA) validate --verbose misc/collection.schema.json collections/*/*.json
	$(JSONSCHEMA) validate --verbose misc/namespace.schema.json collections/*.json

.PHONY: clean
clean:
	$(RMRF) build
