JARFILE = artifact/flixball-2.jar
FLIX_SOURCES = $(shell find src -name '*.flix')

.PHONY: all run check

all: $(JARFILE)

run: $(JARFILE)
	java -jar $(JARFILE)

runH: $(JARFILE)
	java -jar $(JARFILE) -H

runH100: $(JARFILE)
	for i in $$(seq 100); do java -jar $(JARFILE) -H; done

check: $(FLIX_SOURCES) flix.toml
	flix check

$(JARFILE): $(FLIX_SOURCES) flix.toml
	flix build-fatjar
