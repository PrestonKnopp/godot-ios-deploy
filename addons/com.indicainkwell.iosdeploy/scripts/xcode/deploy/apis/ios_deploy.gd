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


const stc = preload('../static.gd')


# ------------------------------------------------------------------------------
#                                   Dependencies
# ------------------------------------------------------------------------------


var ErrorCapturer = stc.get_gdscript('xcode/error_capturer.gd')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


# Handle one bundle at a time and user passes specific
# device id to deploy to on method call
# bundle i.e. MyProject.app
var bundle

var app_args = [] # app args should be joined before passing to ios-deploy
var ignore_wifi_devices = false


# ------------------------------------------------------------------------------
#                                 Private Variables
# ------------------------------------------------------------------------------


var _log = stc.get_logger().make_module_logger(stc.PLUGIN_DOMAIN + '.ios-deploy')
var _error_capturer = ErrorCapturer.new()
var _iosdeploy

var _detect_devices_thread_id = -1


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

	var cfg = stc.get_config()
	cfg.connect('changed', self, '_on_config_changed')
	var tool_path = cfg.get_value('deploy', 'ios_deploy_tool_path',
			stc.DEFAULT_IOSDEPLOY_TOOL_PATH)
	_set_tool_path(tool_path)


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func _set_tool_path(tool_path):
	# TODO: handle if iosdeploy is running when tool is set
	if _iosdeploy != null and _iosdeploy.running():
		OS.alert('Cant set ios deploy tool while running. ' +
			 'Try again after task has finished.')
		return
	var shell = stc.get_gdscript('shell.gd').new()
	_iosdeploy = shell.make_command(tool_path)


func detect_devices(async=true):
	"""
	This should be used only by device_finder.gd. Cause it does the
	parsing. This will probably change later.
	"""
	var args = ['--detect', '--timeout', '1']
	if ignore_wifi_devices:
		args.append('--no-wifi')
	_log.debug('Detect Devices Command: '+str(args))

	if async:
		if _iosdeploy.running(_detect_devices_thread_id):
			# No need to run it again
			return

		_detect_devices_thread_id = _iosdeploy.run_async(
			args,
			self,
			'_detect_devices_finished'
		)
	else:
		return _iosdeploy.run(args)


func install_and_launch_on(device_id, async=true):
	"""
	Install and launch bundle to device_id.

	Looks like you can't just install without launching and setting and
	lldb.
	"""
	return _launch_on(device_id, true, async)


func launch_on(device_id, async=true):
	"""
	Just launch bundle without installing to device_id.
	"""
	return _launch_on(device_id, false, async)


func _launch_on(device_id, install, async):
	"""
	Launch to device_id optionally installing it and running async.
	"""
	assert(bundle != null)
	assert(device_id != null)
	var args = _build_launch_args(device_id, install)
	_log.debug('Deploy Command Launch Args: '+str(args))
	if async:
		_iosdeploy.run_async(args, self, '_deploy_finished', [device_id])
	else:
		var res = _iosdeploy.run(args)
		return res.get_stdout_lines()
	return []


func uninstall():
	assert('Unistall app from ios-deploy not implemented'.empty())


# ------------------------------------------------------------------------------
#                                     Callbacks
# ------------------------------------------------------------------------------


func _on_config_changed(config, section, key, from_value, to_value):
	if section == 'deploy' and key == 'ios_deploy_tool_path':
		if from_value == to_value:
			return
		elif to_value == '':
			_set_tool_path(stc.DEFAULT_IOSDEPLOY_TOOL_PATH)
		else:
			_set_tool_path(to_value)


func _deploy_finished(command, result, device_id):
	var errors = _error_capturer.capture_from(result.output)
	emit_signal('deployed', self, result, errors, device_id)


func _detect_devices_finished(command, result):
	_log.debug('Detect Devices Output: '+str(result.output))
	_detect_devices_thread_id = -1
	emit_signal('device_detection_finished', self, result)


# ------------------------------------------------------------------------------
#                                  Helper Methods
# ------------------------------------------------------------------------------


func _build_launch_args(device_id, install=true):
	var args = [
		'--justlaunch',
		'--id', device_id,
		'--bundle', bundle
	]
	if not install:
		args.append('--noinstall')

	args += _build_app_args()

	return args


func _build_app_args():
	if app_args.size() == 0:
		return []
	return ['--args', stc.join_array(app_args)]


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
