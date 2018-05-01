# required
project="$1"; shift # path to xcode project
team_id=$1; shift   # team id for signing

if [[ ! -f "$project" ]]; then
	>&2 echo 'Error: Need valid path to xcode project as 1st argument'
	>&2 echo '    Given:' $project
	exit 1
fi

# How to validate team_id?
# if [[ ! $team_id ]]; then
# 	>&2 echo 'Error: Need valid team id to sign build'
# 	>&2 echo '    Given:' $team_id
# 	exit 1
# fi

# optional
provision_id=${1:-'none'}; shift # provisioning profile for signing
automanaged=${1:-'false'}; shift # automanage signing: true, false
is_godotv3=${1:-'false'};  shift # : true, false
device_id=${1:-'none'};    shift # id of device to build for
config=${1:-'none'};       shift # config type: Debug, Release

if [[ $provision_id == 'none' ]]; then
	extra_build_settings="$extra_build_settings PROVISIONING_PROFILE_SPECIFIER=$provision_id"
fi

if [[ $is_godotv3 == 'true' ]]; then
	extra_build_settings="$extra_build_settings ENABLE_BITCODE=false"
fi

if [[ $automanaged == 'true' ]]; then
	extra_build_settings="-allowProvisioningUpdates -allowProvisioningDeviceRegistration $extra_build_settings"
fi

if [[ $device_id != 'none' ]]; then
	extra_build_settings="-destination 'platform=iOS,id={device_id}' $extra_build_settings"
fi

xcodebuild build -configuration $config -project "$project" $destination $extra_build_settings DEVELOPMENT_TEAM=$team_id
