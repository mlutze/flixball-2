JARFILE = artifact/flixball-2.jar
FLIX_SOURCES = $(shell find src -name '*.flix')

.PHONY: all run

all: $(JARFILE)

run: $(JARFILE)
	java -jar $(JARFILE)

$(JARFILE): $(FLIX_SOURCES) flix.toml
	flix build-fatjar
