# device_finder.gd
extends 'Finder.gd'


# ------------------------------------------------------------------------------
#                                     Subtypes
# ------------------------------------------------------------------------------


var Device = stc.get_gdscript('xcode/device.gd')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var _regex = stc.get_gdscript('regex.gd').new()
var _ios_deploy = stc.get_gdscript('xcode/ios_deploy.gd').new()


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _init():
	# Captures:
	# 1. device id
	# 2. device type info
	# 3. name
	# 4. connection
	#                    1         2                     3                       4
	var pattern = "Found (\\w*) \\((.*)\\) a\\.k\\.a\\. '(.*)' connected through (\\w*)\\."
	assert(_regex.compile(pattern) == OK)

	_ios_deploy.connect('device_detection_finished', self,
			'_on_ios_deploy_device_detection_finished')


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------

# ios-deploy Output Example, first line is always there:
# [....] Waiting up to 1 seconds for iOS device to be connected
# [....] Found 3345abc45b3cab4c5eb5c4bfb3c5998abc3b320a (P105AP, iPad mini, iphoneos, armv7) a.k.a. 'iPad Name' connected through USB.
func _ios_deploy_find_devices():
	_ios_deploy.detect_devices()


func _instruments_find_devices():
	var listknowndevices = stc.get_shell_script(stc.shell.listknowndevices)
	var res = _sh.run(listknowndevices)
	if res.code != 0:
		return []

	var devices = []

	# for some reason multiline output is all in first element
	for line in res.get_stdout_lines():
		# skip sims until add support for x86 project gen
		if line.find('] (Simulator)') != -1:
			continue

		var device = Device.new()
		var end_name_idx = line.rfind('[')
		device.name = line.substr(0, end_name_idx).strip_edges()


		var end_id_idx = line.find(']', end_name_idx)

		# move passed '['
		end_name_idx += 1

		var id_length = end_id_idx - end_name_idx
		device.id = line.substr(end_name_idx, id_length)

		device.type = device.Type.Unknown
		if device.name.findn('macbook') != -1:
			device.type = device.Type.Mac
		elif device.name.findn('iphone') != -1:
			device.type = device.Type.iPhone
		elif device.name.findn('ipad') != -1:
			device.type = device.Type.iPad

		devices.append(device)
	
	_finished(devices)


# ------------------------------------------------------------------------------
#                                     Handlers
# ------------------------------------------------------------------------------


func _on_ios_deploy_device_detection_finished(iosdeploy, result):
	var devices = []

	# Parse device information from detect_devices output
	for line in result.get_stdout_lines():
		var captures = _regex.search(line)
		if captures.size() == 0:
			# Whole pattern didn't match
			continue

		var device = Device.new()
		device.id = captures[1]
		device.type_info = captures[2]
		device.name = captures[3]

		# extra required capture checks

		# device.type will never be sim or mac
		# from ios-deploy
		if device.type_info.find('iPhone') > -1:
			device.type = Device.Type.iPhone
		elif device.type_info.find('iPad') > -1:
			device.type = Device.Type.iPad

		if captures[4].find('USB') == -1:
			device.connection = Device.Connection.WIFI

		devices.append(device)

	_finished(devices)


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func begin_find():
	_ios_deploy_find_devices()

