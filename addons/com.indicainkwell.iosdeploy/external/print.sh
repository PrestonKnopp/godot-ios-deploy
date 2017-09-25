#!/usr/bin/env sh

log=/Users/prestonkuhnopp/Desktop/arg-log.txt
echo "$@" >> $log

output="$1"; shift
exec > "$output"

echo Output: "$output" >> $log

echo "Hello World Test"

program="$1"; shift
exec "$program" "$@"
