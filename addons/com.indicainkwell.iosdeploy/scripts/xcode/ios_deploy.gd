# ios_deploy.gd
#
# API for ios-deploy binary
#
extends Reference


# ------------------------------------------------------------------------------
#                                      Signals
# ------------------------------------------------------------------------------


signal deployed(this, result)


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const stc = preload('../static.gd')


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


var _log = stc.get_logger()
var _log_mod = stc.PLUGIN_DOMAIN + '.ios-deploy'
var _bash = stc.get_gdscript('shell.gd').new().make_command('/bin/bash')
var _bashinit = ['-l', '-c']


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func detect_devices():
	"""
	This should be used only by device_finder.gd. Cause it does the
	parsing. This will probably change later.
	"""
	var args = ['--detect', '--timeout', '1']
	if ignore_wifi_devices:
		args.append('--no-wifi')
	var res = _bash.run(_bashinit, _build_deploy_cmd(args))
	_log.info(res.output, _log_mod)
	return res.output[0].split('\n', false)


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
	var args = _build_launch_args(install)
	if async:
		_bash.run_async(_bashinit + [_build_deploy_cmd(args)], self, '_deploy_finished')
	else:
		var res = _bash.run(_bashinit,  _build_deploy_cmd(args))
		return res.output[0].split('\n', false)
	return []


func uninstall():
	assert('Unistall app from ios-deploy not implemented'.empty())


# ------------------------------------------------------------------------------
#                                     Callbacks
# ------------------------------------------------------------------------------


func _deploy_finished(command, result):
	# TODO: parse result output and detect deploy failure
	emit_signal('deployed', self, result)


# ------------------------------------------------------------------------------
#                                  Helper Methods
# ------------------------------------------------------------------------------


func _build_deploy_cmd(args):
	return 'ios-deploy ' + _join(args)


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
	return ['--args', _join(app_args)]


func _join(arr, delim=' '):
	"""
	Implementation for joining arrays as Godotv2 does not support it.
	"""
	assert(arr != null and typeof(arr) == TYPE_ARRAY)
	var size = arr.size()
	if size == 1:
		return arr[0]
	if size == 0:
		return ''
	var res = ''
	for i in range(0, size - 1):
		res += str(arr[i]) + delim
	res += arr[size - 1]
	return res


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
