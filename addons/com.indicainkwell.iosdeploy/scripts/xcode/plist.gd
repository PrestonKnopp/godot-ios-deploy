# plist.gd
extends Reference


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const stc = preload('../static.gd')


# ------------------------------------------------------------------------------
#                                     Subtypes
# ------------------------------------------------------------------------------


var Json = stc.get_gdscript('json.gd')
var Shell = stc.get_gdscript('shell.gd')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var _path
var _backing = {}
var _pbuddy = Shell.new().make_command('/usr/libexec/PlistBuddy')
var _log = stc.get_logger()
var _log_mod = stc.PLUGIN_DOMAIN + '.plist'


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _init():
	_log.add_module(_log_mod)


# ------------------------------------------------------------------------------
#                                      Values
# ------------------------------------------------------------------------------


func get_value(key, default):
	assert("PList is write only for now. Min needed support for xcode".empty())


func set_value(key, value):
	_backing[key] = value


# ------------------------------------------------------------------------------
#                                     File Ops
# ------------------------------------------------------------------------------


func open(path):
	_path = stc.globalize_path(path)

	if not File.new().file_exists(_path):
		_log.error('file not found at ' + _path, _log_mod)
		return ERR_FILE_NOT_FOUND

	# TODO: some way to verify if it is plist
	
	return OK


func save():
	if _path == null:
		_log.error('must open a path before saving', _log_mod)
		return FAILED
	
	var res = open(_path)
	if res != OK:
		return res

	var args = _build_pbuddy_args()
	res = _pbuddy.run(args, _path)
	if sh_res.output.size() > 0 and sh_res.output[0].length() > 0:
		_log.info('TODO: check how to find out if pbuddy failed')
	
	return OK


# ------------------------------------------------------------------------------
#                                      Helper
# ------------------------------------------------------------------------------


func _build_pbuddy_args():
	var args = []
	for key in _backing:
		args.append('-c')
		args.append('Set %s %s' % [key, _backing[key]])
	return args
