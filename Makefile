# Dummy makefile.
CARBON?=carbon
test:
	busted --lua=${CARBON} spec

all: test
