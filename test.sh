#!/bin/bash
set -e

usage () {
echo \
"$0 [OPTION]... [FILE]...

-t	Compile the theory/*.dk files
-e	Encode sttfa file to cts in ctslib/
-l	Compile cts Lib files in ctslib/
-u	run Universo on FILES
-m	Merge solution in final/
-a	run All of the above
-v	Verbose mode
-h	show Help
"
}

generate_graph () {
	local dotfile=$(mktemp)

	echo "digraph {" > $dotfile
	(cd lib && dkdep -i ${files[@]}) | \
	sed 	-e 's/:/-> {/' \
		-e 's/lib\///g' \
		-e 's/$/ };|/' \
		-e 's/\w*\.dk //' \
		-e 's/\.dko//g' \
		-e 's/^/   /' | \
	tr '|' '\n' \
	>> $dotfile
	echo "}" >> $dotfile

	dot -Tpdf $dotfile -o depend.pdf

	rm -rf $dotfile
}

lib2ctslib () {
	mkdir -p ctslib
	for f in ${files[@]}
	do
		# echo "[dkmeta] converting lib/$f"

		OCAMLRUNPARAM='b' \
		dune exec dkmeta -- -I ./theory \
		 -m meta/meta.dk lib/$f > ctslib/$f
	done
}

check_theory () {
	dkcheck -eq theory/*.dk
}

clean () {
	rm -rf *.dko output/ _build/ ctslib/ final/
}

# ensure files are in format like eq.dk (not eq, lib/eq.dk)
clean_files () {
        echo "$@"       | \
        tr ' ' '\n'     | \
        sed -e '/^ *$/d' \
            -e 's/^lib\///' \
            -e 's/\.dk$//' \
            -e 's/$/.dk/' | \
        tr '\n' ' '
}

compile_ctslib () {
	# printf reuses same pattern until args exhaust
	dkcheck -I ./theory -I ./ctslib/ -e $(printf "ctslib/%s " ${files[@]})
}

run_universo () {
	OCAMLRUNPARAM='b' \
	dune exec universo -- -o output \
	--theory theory/cts.dk --config config/universo_cfg.dk \
	-I theory/ \
	$(printf "ctslib/%s " $files)
}

merge_solution () {
	mkdir -p final

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

	dkcheck -e -I ./theory/ -I ./final/ $(dkdep -si -I ./final $(printf "./final/%s " $files))

}


# main <file1> <file2> ...
main () {

	while getopts 'tecumavh' c ; do
	case $c in
		t) theocomp=true ;;
		e) stffaenc=true ;;
		g) gengraph=true ;;
		l) ctscomp=true ;;
		u) rununiv=true ;;
		m) mergesol=true ;;
		a) runall=true ;;
		v) verbose=true ;;
		h) usage ; return 0 ;;
	esac
	done

	shift $((OPTIND - 1))

	echo "@ = $@ ; # = $#"

	# use all files in lib/ if no args are given
	if [ $# -eq 0 ]; then
		files=$(ls -1 lib/*.dk | tr '\n' ' ')
	else
		files=$@
	fi

	files=`clean_files $files`

	# ensure files are in order of dependencies
	files=$(cd lib && dkdep -si $files)

	# echo "files = $files"

	if [[ $runall = true ]] || [[ $theocomp = true ]]; then
		echo "Checking theory files..."
		check_theory
	fi

	if [[ $runall = true ]] || [[ $sttfaenc = true ]]; then
		lib2ctslib
	fi

	if [[ $runall = true ]] || [[ $gengraph = true ]]; then
		generate_graph
	fi

	if [[ $runall = true ]] || [[ $ctscomp = true ]]; then
		compile_ctslib
	fi

	if [[ $runall = true ]] || [[ $rununiv = true ]]; then
		run_universo
	fi

	if [[ $runall = true ]] || [[ $mergesol = true ]]; then
		merge_solution
	fi
}

main $@
