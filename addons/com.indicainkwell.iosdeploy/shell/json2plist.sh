json="$1"
ofile="$2"
echo "$json" | plutil -convert xml1 -o "$ofile" -
