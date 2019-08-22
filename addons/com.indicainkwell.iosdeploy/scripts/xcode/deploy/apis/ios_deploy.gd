# ios_deploy.gd
#
# API for ios-deploy binary
#
extends Reference


# ------------------------------------------------------------------------------
#                                      Signals
# ------------------------------------------------------------------------------


signal deployed(this, result, errors, device_id)
signal device_detection_finished(this, result)


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const DEFAULT_TOOL_PATH = '/usr/local/bin'
const stc = preload('../static.gd')


# ------------------------------------------------------------------------------
#                                   Inner Classes
# ------------------------------------------------------------------------------


class LaunchResult extends Reference:
	var errors = []
	var result = null

# ------------------------------------------------------------------------------
#                                   Dependencies
# ------------------------------------------------------------------------------


var ErrorCapturer = stc.get_gdscript('xcode/error_capturer.gd')
var Regex = stc.get_gdscript('regex.gd')
var Device = stc.get_gdscript('xcode/device.gd')
var Shell = stc.get_gdscript('shell.gd')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var ignore_wifi_devices = false


# ------------------------------------------------------------------------------
#                                 Private Variables
# ------------------------------------------------------------------------------


var _log = stc.get_logger().make_module_logger(stc.PLUGIN_DOMAIN + '.ios-deploy')
var _error_capturer = ErrorCapturer.new()
var _regex = Regex.new()
var _iosdeploy


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _init():
	# 1. Error Code
	# 2. Error Message
	# ----------------------------------------------->1            2
	_error_capturer.set_regex_pattern('.*[ !! ] Error 0x(\\d*): \\w* (\\w*)')
	_error_capturer.set_error_captures_map({
		code = 1,
		message = 2
	})

	# Captures:
	# 1. device id
	# 2. device type info
	# 3. name
	# 4. connection
	#                    1         2                     3                       4
	var pattern = "Found (\\w*) \\((.*)\\) a\\.k\\.a\\. '(.*)' connected through (\\w*)\\."
	assert(_regex.compile(pattern) == OK)

	set_tool_path(get_default_tool_path())


# ------------------------------------------------------------------------------
#                                Setters and Getters
# ------------------------------------------------------------------------------


var tool_path setget set_tool_path,get_tool_path
func set_tool_path(tool_path):
	_iosdeploy = Shell.new().make_command(tool_path)

func get_tool_path():
	return _iosdeploy.name


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func get_default_tool_path():
	return DEFAULT_TOOL_PATH


func get_detected_devices():
	"""
	@returns Array<Device>
	"""
	var args = ['--detect', '--timeout', '1']
	if ignore_wifi_devices:
		args.append('--no-wifi')
	_log.debug('Detect Devices Command Args: '+str(args))
	var result = _iosdeploy.run(args)
	if result.code != OK:
		_log.error('Error<%s>: Failed to get any detected device ids: %s'%[result.code, result.output])
		return []
	return _parse_iosdeploy_result(result.get_stdout_lines())


# ios-deploy Output Example, first line is always there:
# [....] Waiting up to 1 seconds for iOS device to be connected
# [....] Found 3345abc45b3cab4c5eb5c4bfb3c5998abc3b320a (P105AP, iPad mini, iphoneos, armv7) a.k.a. 'iPad Name' connected through USB.
func _parse_iosdeploy_output(output):
	var devices = []

	for line in output:
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
	
	return devices


func install_and_launch_app(device_id, app_path, app_args):
	"""
	Install and launch app_path to device_id with app_args.
	@see launch_app()
	"""
	# Looks like you can't just install without launching and setting and lldb.
	return launch_app(device_id, app_path, app_args, true)


func just_launch_app(device_id, app_path, app_args):
	"""
	Just launch app_path with app_args without installing to device_id.
	@see launch_app()
	"""
	return launch_app(device_id, app_path, app_args, false)


func launch_app(device_id, app_path, app_args, install):
	"""
	Launch app_path with app_args to device_id optionally installing it.
	@device_id: String
	@app_path: String the path to the app bundle on the local system.
	@app_args: [String] the args to pass to app when launching it.
	@install: bool install the app first?
	"""
	var args = _build_launch_args(device_id, app_path, app_args
			install)
	_log.debug('launch app built args: '+str(args))
	var result = _iosdeploy.run(args)
	var errors = _error_capturer.capture_from(result.output)
	var launch_result = LaunchResult.new()
	launch_result.result = result
	launch_result.errors = errors
	return launch_result

func _build_launch_args(device_id, app_path, app_args, install=true):
	var args = [
		'--justlaunch',
		'--id', device_id,
		'--bundle', app_path
	]
	if not install:
		args.append('--noinstall')

	args += _build_app_args(app_args)

	return args


func _build_app_args(app_args):
	if typeof(app_args) == TYPE_ARRAY and app_args.size() > 0:
		return ['--args', stc.join_array(app_args)]
	return []


# ------------------------------------------------------------------------------
#                                  Bundle File Ops
# ------------------------------------------------------------------------------


func has_bundle():
	assert('Check bundle from ios-deploy not implemented'.empty())


func list_bundles():
	assert('List bundles from ios-deploy not implemented'.empty())


func list_files():
	assert('List files from ios-deploy not implemented'.empty())


func upload(file, to):
	assert('Upload file from ios-deploy not implemented'.empty())


func download(file, to):
	assert('Download file from ios-deploy not implemented'.empty())


func remove(file):
	assert('Remove file from ios-deploy not implemented'.empty())


func mkdir(dir):
	assert('Mkdir from ios-deploy not implemented'.empty())
