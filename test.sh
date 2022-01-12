#!/bin/bash
set -e
n_univ=$1
rm -rf *.dko output/ _build/ ctslib/
mkdir ctslib

./config/generate_config.py $n_univ > ./config/universo_cfg.dk
./theory/generate_cts.py $n_univ   > ./theory/cts.dk

dkcheck -e theory/*.dk

for f in lib/*.dk
do
echo "[dkmeta] converting $f"

# OCAMLRUNPARAM='b' \
dune exec dkmeta -- -I ./theory \
 -m meta/meta.dk $f > ctslib/$(basename $f)
done


files=$(dkdep -I ./theory/ -I ./ctslib/ -s theory/*.dk ctslib/*.dk)
lib_files=$(echo $files | sed 's/[^ ]*theory\/[^ ]*.dk//g' -)

dkcheck -I ./theory -I ./ctslib/ -e $files

# OCAMLRUNPARAM='b' \
dune exec universo -- -o output \
--theory theory/cts.dk --config config/universo_cfg.dk \
-I theory/ -l \
$lib_files

