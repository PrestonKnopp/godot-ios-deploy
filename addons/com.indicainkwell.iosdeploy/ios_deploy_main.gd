tool
extends EditorPlugin


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const stc = preload('scripts/static.gd')


# ------------------------------------------------------------------------------
#                                     Subtypes
# ------------------------------------------------------------------------------


var Controller = stc.get_gdscript('controller.gd')
var Logger = stc.get_gdscript('logger.gd')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var controller
var _log


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _enter_tree():
	_initialize_logger()

	if not meets_software_requirements():
		return

	_log.verbose('Meets software requirements')
	controller = Controller.new()
	add_control_to_container(CONTAINER_TOOLBAR, controller.get_view())
	add_menu(controller.get_menu())


func _exit_tree():
	if controller != null:
		controller.cleanup()
		controller = null


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func _initialize_logger():
	"""
	Add logger as a child of plugin and in it's own group to simulate a
	global that can be accessed via stc.get_logger()
	"""
	var logger = Logger.new()
	add_child(logger)
	logger.add_to_group(stc.PLUGIN_DOMAIN)
	logger.set_name(stc.LOGGER_DOMAIN)
	_log = stc.get_logger().make_module_logger(stc.LOGGER_DOMAIN)


func meets_software_requirements():
	var meets = true

	if OS.get_name() != 'OSX':
		_log.error('macOS is needed to build and deploy iOS projects')
		meets = false

	if not ext_sw_exists('ios-deploy'):
		_log.error('ios-deploy is missing: install ios-deploy with homebrew -- brew install ios-deploy')
		meets = false

	if not ext_sw_exists('xcodebuild'):
		_log.error('xcodebuild is missing: install xcode command line tools')
		meets = false

	return meets


func ext_sw_exists(software):
	var out = []
	OS.execute('command', ['-v', software], true, out)
	return out.size() > 0


func add_menu(menu):
	if stc.get_version().is2():
		get_base_control().add_child(menu)
	else:
		get_editor_interface().get_base_control().add_child(menu)
