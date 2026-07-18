JARFILE = artifact/flixball-2.jar
FLIX_SOURCES = $(shell find src -name '*.flix')

.PHONY: all run check

all: $(JARFILE)

run: $(JARFILE)
	java -jar $(JARFILE)

runH: $(JARFILE)
	java -jar $(JARFILE) -H

check: $(FLIX_SOURCES) flix.toml
	flix check

$(JARFILE): $(FLIX_SOURCES) flix.toml
	flix build-fatjar
