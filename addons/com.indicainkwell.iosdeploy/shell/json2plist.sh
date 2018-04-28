ijsonfile="$1"
ofile="$2"
plutil -convert xml1 -o "$ofile" -- "$ijsonfile"
