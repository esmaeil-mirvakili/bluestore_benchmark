#!/bin/bash
portions=(5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95)
path_del="/"
prefix="$1/results"
post_fix="_fio.json"

for portion in "${portions[@]}"
do
	sudo ./run-fio-read-affect-experiment.sh $portion
	path=$prefix$path_del$portion
	sudo mkdir -p "$path"
	name=$(find . -type f -name "codel_log_batch*"  | cut -c3-)
	sudo mv codel_* $path
	sudo mv dump-fio-bench-* $path$path_del$name$post_fix
done