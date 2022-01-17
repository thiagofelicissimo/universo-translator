#!/bin/bash
set -e
rm -rf *.dko output/ _build/ ctslib/ final/ lib2/
mkdir lib2

dkcheck -e theory/*.dk

for f in lib/*.dk
do
	echo "[dkmeta] converting $f"
	
	OCAMLRUNPARAM='b' \
	dune exec dkmeta -- -I ./theory \
	 -m meta.dk $f > lib2/$(basename $f)
done
dkcheck -e -I ./theory/ -I ./lib2/ ./lib2/*.dk 
