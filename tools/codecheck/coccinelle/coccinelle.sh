#!/bin/bash
check_file="$1"
cocci_dir="kernel/linux-5.15/scripts/coccinelle/"

cocci_files=$(find $cocci_dir -type f)

for cocci_file in $cocci_files; do
	./tools/codecheck/coccinelle/usr/local/bin/spatch --very-quiet -D report --no-show-diff $cocci_file $check_file
done
