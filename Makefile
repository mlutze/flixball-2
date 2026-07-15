JARFILE = artifact/flixball-2.jar
FLIX_SOURCES = $(shell find src -name '*.flix')

.PHONY: run

run: $(JARFILE)
	java -jar $(JARFILE)

$(JARFILE): $(FLIX_SOURCES) flix.toml
	flix build-fatjar
