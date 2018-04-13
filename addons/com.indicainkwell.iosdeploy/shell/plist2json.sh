plist_file="$1"
plutil -convert json -o - -- "$plist_file"
