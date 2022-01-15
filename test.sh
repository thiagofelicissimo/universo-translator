#!/bin/bash
set -e

generate_graph () {
	echo "digraph {" > graph.dot
	(cd lib && dkdep -i $*) | \
	sed 	-e 's/:/-> {/' \
		-e 's/lib\///g' \
		-e 's/$/ };|/' \
		-e 's/\w*\.dk //' \
		-e 's/\.dko//g' \
		-e 's/^/   /' | \
	tr '|' '\n' \
	>> graph.dot
	echo "}" >> graph.dot

	dot -Tpdf graph.dot -o depend.pdf
}


rm -rf *.dko output/ _build/ ctslib/ final/
mkdir ctslib

dkcheck -eq theory/*.dk

# use all files in lib/ if no args are given
if [ $# -eq 0 ]; then
	files=$(ls -1 lib/*.dk | tr '\n' ' ')
else
	files=$@
fi


# files=${@:-$(ls -1 lib/*.dk | tr '\n' ' ')}

# ensure files are in format like eq.dk (not eq, lib/eq.dk)
files=$(echo "$files" | \
        tr ' ' '\n' | \
	sed -e '/^ *$/d' \
	    -e 's/^lib\///' \
            -e 's/\.dk$//' \
	    -e 's/$/.dk/' | \
	tr '\n' ' ')


# ensure files are in order of dependencies
files=$(cd lib && dkdep -si $files) 

# Generate graph
generate_graph $files


for f in ${files[@]}
do
	# echo "[dkmeta] converting lib/$f"

	OCAMLRUNPARAM='b' \
	dune exec dkmeta -- -I ./theory \
	 -m meta/meta.dk lib/$f > ctslib/$f
done


# printf reuses same pattern until args exhaust
dkcheck -q -I ./theory -I ./ctslib/ -e $(printf "ctslib/%s " ${files[@]}) 


OCAMLRUNPARAM='b' \
dune exec universo -- -o output \
--theory theory/cts.dk --config config/universo_cfg.dk \
-I theory/ \
$(printf "ctslib/%s " $files)


mkdir final
for f in $files
do
	base=$(basename $f .dk)

        OCAMLRUNPARAM='b' \
	dune exec dkmeta -- -m output/`echo $base`_sol.dk \
	output/$base.dk -I theory/ -I output/ \
	> final/$base.dk

	sed -i 's/#REQUIRE[^.]*.//' final/$base.dk
	sed -i '/./,$!d' final/$base.dk
done


echo "

CHECKING FINAL FILES
====================
"

dkcheck -e -I ./theory/ -I ./final/ $(dkdep -si -I ./final ./final/*.dk)

