# DeployTool.gd
#
# Provides a basic interface for tools to implement to ease the communication
# between tool strategies and the user.
extends Reference


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const stc = preload('../../../static.gd')


# ------------------------------------------------------------------------------
#                                   Dependencies
# ------------------------------------------------------------------------------


var Device = stc.get_gdscript('xcode/device.gd')
var Shell = stc.get_gdscript('shell.gd')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var _log = stc.get_logger().make_module_logger(str(
		stc.PLUGIN_DOMAIN, '.', get_name()))
var _path


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func _init():
	set_path(get_default_path())


func set_path(path):
	""" @override
	Set the tool path to given path. The path may be a directory depending
	on the implementing tool.
	Override this method to react when tool path is being set.
	Pass null to reset tool path to default.
	@path String?
	"""
	if path == null:
		_path = get_default_path()
	else:
		_path = path

func get_path(path):
	"""
	@returns String
	"""
	return _path

func get_default_path():
	""" @override
	Gets the default path to this tool. This may be a path to a directory.
	It is left up to the implementation to decide how to use the path.
	"""
	return ''

func get_name():
	""" @override
	@returns String
	"""
	return ''

func get_extra_options():
	""" @override
	Get any extra options that the user should be know.
	@returns [String]
	"""
	return []

func handle_extra_option(option):
	""" @virtual
	Handle the option use has chosen to run.
	@option: String
	"""
	pass
