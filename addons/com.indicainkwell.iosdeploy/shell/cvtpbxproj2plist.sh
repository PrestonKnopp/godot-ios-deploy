# convert pbxproj to plist
pbxproj_path="$1"
plutil -convert xml1 -- "$pbxproj_path"
