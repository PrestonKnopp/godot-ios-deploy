tool
extends EditorPlugin


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const stc = preload('scripts/static.gd')


# ------------------------------------------------------------------------------
#                                     Subtypes
# ------------------------------------------------------------------------------


var MainController = stc.get_gdscript('controllers/main_controller.gd')
var PoolStringConverter = stc.get_gdscript('pool_string_converter.gd')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var main_controller
var _log


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _enter_tree():

	_init_logger()

	if not meets_software_requirements():
		return
	
	_log.verbose('Meets software requirements')
	
	main_controller = MainController.new()
	add_child(main_controller)


func _exit_tree():
	stc.free_plugin_singletons()


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func _init_logger():
	var log_env_var = stc.LOGGER_DOMAIN.replace('.', '_').to_upper()
	var log_level_env = log_env_var + '_LEVEL'
	if OS.has_environment(log_level_env):
		var levels = stc.get_logger().LEVELS
		var level = OS.get_environment(log_level_env)
		var idx = levels.find(level.to_upper())
		if idx != -1:
			stc.get_logger().set_default_output_level(idx)
		else:
			stc.get_logger().info('Invalid Logger Level: ' + level)
			stc.get_logger().info('- Expected: ' + str(levels))

	var log_file_env = log_env_var + '_FILE'
	if OS.has_environment(log_file_env):
		var file = OS.get_environment(log_file_env)
		stc.get_logger().info('Redir logging to file: ' + file)
		stc.get_logger().set_default_logfile_path(file)
		stc.get_logger().set_default_output_strategy(stc.get_logger().STRATEGY_FILE)

	_log = stc.get_logger().make_module_logger(stc.PLUGIN_DOMAIN)


func meets_software_requirements():
	var meets = true

	if OS.get_name() != 'OSX':
		_log.error('macOS is needed to build and deploy iOS projects')
		meets = false

	if not ext_sw_exists('/usr/local/bin/ios-deploy'):
		# TODO: don't hard code path to ios-deploy
		_log.error('ios-deploy is missing: install ios-deploy with homebrew -- brew install ios-deploy')
		meets = false

	if not ext_sw_exists('xcodebuild'):
		_log.error('xcodebuild is missing: install xcode command line tools -- xcode-select --install')
		meets = false

	return meets


func ext_sw_exists(software):
	var out = []
	OS.execute('command', PoolStringConverter.convert_array(['-v', software]), true, out)
	_log.verbose(out[0])
	return out[0].find(software) > -1


func add_menu(menu):
	if stc.get_version().is2():
		call('get_base_control').add_child(menu)
	else:
		get_editor_interface().get_base_control().add_child(menu)
