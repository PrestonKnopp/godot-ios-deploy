# run with bash, so provision_path will be 2 arg
provision_path="$1"
if [[ ! -f "$provision_path" ]]; then
	echo '{}'
	exit 1
fi

# Strip signature substitutes unsupported plist objects with string
#
# plist objects not supported by json in provision profile:
#  - date -> string
#  - data -> string
awk '
/</ {
	if(index($0, "</plist>")) {
		print "</plist>"
		exit 0
	}
	gsub(/<dat[ea]>/, "<string>")
	gsub(/<\/dat[ea]>/, "</string>")
	print $0
}
' "$provision_path" | plutil -convert json -o - -
