tool
extends EditorPlugin


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const stc = preload('scripts/static.gd')


# ------------------------------------------------------------------------------
#                                   Dependencies
# ------------------------------------------------------------------------------


var MainController = stc.get_gdscript('controllers/main_controller.gd')
var PoolStringConverter = stc.get_gdscript('pool_string_converter.gd')
var Deploy = stc.get_gdscript('xcode/deploy.gd')


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

	stc.get_config().connect('changed', self, '_on_config_changed')
	
	main_controller = MainController.new()
	add_child(main_controller)


func _exit_tree():
	stc.get_config().save()
	stc.free_plugin_singletons()


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func _init_logger():

	# Check config for initial logger level
	var ll = stc.get_config().get_value('meta', 'log_level', stc.get_logger().get_default_output_level())
	var lf = stc.get_config().get_value('meta', 'log_file', '')
	stc.get_logger().set_default_output_level(ll)
	if lf != '':
		stc.get_logger().set_default_logfile_path(lf)
		stc.get_logger().set_default_output_strategy(stc.get_logger().STRATEGY_FILE)

	# env overrides config
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


func _on_config_changed(config, section, key, from_value, to_value):
	if section == 'meta':
		if key == 'log_level':
			for module in stc.get_logger().get_modules().values():
				module.set_output_level(to_value)
		elif key == 'log_file':
			for module in stc.get_logger().get_modules().values():
				if to_value == '':
					module.set_common_output_strategy(stc.get_logger().STRATEGY_PRINT)
				else:
					module.set_logfile(to_value)
					module.set_common_output_strategy(stc.get_logger().STRATEGY_FILE)


func meets_software_requirements():
	var meets = true

	if OS.get_name() != 'OSX':
		_log.error('macOS is needed to build and deploy iOS projects')
		meets = false
	

	var deploy = Deploy.new()
	var at_least_one_available = false
	for strat in deploy.get_supported_strategies():
		for key in strat.get_config_keys():
			var value = stc.get_config().get_value(
					strat.get_config_section(), key)
			strat.handle_config_key_change(key, value)
		var available = strat.tool_available()
		if not available:
			var tname = strat.get_tool_name()
			_log.error('%s is missing: Install if needed with `brew
					install %s`' % [tname, tname])
		if available:
			at_least_one_available = available
	if meets:
		meets = at_least_one_available

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


func get_editor_settings():
	if has_method('get_editor_interface'):
		return call('get_editor_interface')\
		      .call('get_editor_settings')
	else:
		return .get_editor_settings()
