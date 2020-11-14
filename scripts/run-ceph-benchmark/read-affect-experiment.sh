#!/bin/bash
portions=(10 20 30 40 50 60 70 80 90)
path_del="/"
prefix="$1/results"
post_fix="_fio.json"

for portion in "${portions[@]}"
do
	sudo ./run-fio-read-affect-experiment.sh $portion
	path=$prefix$path_del$portion
	sudo mkdir -p "$path"
	name=$(find . -type f -name "codel_*"  | cut -c3-)
	sudo mv codel_* $path
	sudo mv dump-fio-bench-* $path$path_del$name$post_fix
done