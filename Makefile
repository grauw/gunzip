all:
	mkdir -p gen bin
	node tools/gencrctable.js > gen/crctable.asm
	java -jar tools/glass.jar -I gen -I lib/neonlib/src src/COM.asm bin/gunzip.com bin/gunzip.sym

dist: all
	cp README.md CHANGES.md LICENSE bin/
	rm -f bin/gunzip.zip
	cd bin && zip gunzip.zip gunzip.com README.md CHANGES.md LICENSE

run: all
	openmsx -machine Panasonic_FS-A1GT -ext ide -script openmsx.tcl

run2: all
	openmsx -machine Philips_NMS_8245 -ext ide -script openmsx.tcl
