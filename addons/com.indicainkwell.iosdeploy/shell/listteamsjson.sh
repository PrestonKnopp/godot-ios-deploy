teamsplist=$(defaults read com.apple.dt.xcode IDEProvisioningTeams)

if [[ $teamsplist == '' ]]; then
	echo '{}'
else
	echo $teamsplist | plutil -convert json -o - -
fi
