pbxproj_path="$1"
plutil -convert json -o - -- "$pbxproj_path"
