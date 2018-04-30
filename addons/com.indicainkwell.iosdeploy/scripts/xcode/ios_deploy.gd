# ios_deploy.gd
#
# API for ios-deploy binary
#
extends Reference


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const stc = preload('../static.gd')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var device_id
var bundle
#var bundle_id

var app_args = [] # app args should be joined before passing to ios-deploy
var ignore_wifi_devices = false


# ------------------------------------------------------------------------------
#                                 Private Variables
# ------------------------------------------------------------------------------


var _log = stc.get_logger()
var _log_mod = stc.PLUGIN_DOMAIN + '.ios-deploy'
var _shell = stc.get_gdscript('shell.gd').new()
var _deploy = _shell.make_command('ios-deploy')


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func detect_devices():
	"""
	This should be used only by device_finder.gd. Cause it does the
	parsing. This will probably change later.
	"""
	var res = _deploy.run('--detect', '--timeout', '1')
	return res.output[0].split('\n', false)


func install_and_launch():
	"""
	Install and launch bundle to device_id.

	Looks like you can't just install without launching and setting and
	lldb.
	"""
	assert(bundle != null)
	assert(device_id != null)
	var res = _deploy.run(
		'--justlaunch',
		'--id', device_id,
		'--bundle', bundle,
		_build_app_args()
	)
	return res.output[0].split('\n', false)


func launch():
	"""
	Just launch bundle without installing to device_id.
	"""
	assert(bundle != null)
	assert(device_id != null)
	var res = _deploy.run(
		'--justlaunch',
		'--noinstall',
		'--id', device_id,
		'--bundle', bundle,
		_build_app_args()
	)
	return res.output[0].split('\n', false)


func uninstall():
	assert('Unistall app from ios-deploy not implemented'.empty())


# ------------------------------------------------------------------------------
#                                  Helper Methods
# ------------------------------------------------------------------------------


func _build_app_args():
	if app_args.size() == 0:
		return []
	return ['--args', _join(app_args)]


func _join(arr, delim=' '):
	"""
	Implementation for joining arrays as Godotv2 does not support it.
	"""
	assert(arr)
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
