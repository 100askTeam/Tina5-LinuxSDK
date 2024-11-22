#!/bin/bash

smatch="$(dirname $0)/smatch"
#smatch_args="-p=kernel --data=$(dirname $0)/smatch_data"
smatch_args="-p=kernel --succeed --full-path --spammy"
#echo "$0: Executing '$smatch ${smatch_args} $*' ..."
$smatch ${smatch_args} $*
