# settings_menu_controller.gd
tool
extends 'Controller.gd'


var SettingsMenuScene = stc.get_scene('settings_menu.tscn')

var _log = stc.get_logger().make_module_logger(stc.PLUGIN_DOMAIN + '.settings-menu-controller')
var _xcode


func _enter_tree():
	view = SettingsMenuScene.instance()
	view.connect('pressed', self, '_on_pressed')
	view.connect('about_to_show', self, '_on_about_to_show')
	view.connect('popup_hide', self, '_on_hide')
	get_plugin().add_menu(view)


func set_xcode(xcode):
	_xcode = xcode


func _on_pressed(view, press_section):
	if press_section == view.PRESS_SECTION.ONBOARDING_FLOW_OPEN:
		get_parent().get_menu().popup_centered()
		_log.debug('opened onboarding flow')
	elif press_section == view.PRESS_SECTION.XCODE_PROJ_COPY:
		OS.set_clipboard(_xcode.project.get_xcodeproj_path())
		_log.debug('copied xcodeproj path to clipboard')
	elif press_section == view.PRESS_SECTION.XCODE_PROJ_OPEN:
		OS.shell_open('file://' + _xcode.project.get_path())
		_log.debug('opened xcodeproj folder with fs')
	elif press_section == view.PRESS_SECTION.XCODE_PROJ_FILL_EXPORT:
		stc.get_gdscript('export_presets.gd').new().fill()
		_log.info('Filled export presets with current iosdeploy settings')


func _on_about_to_show():
	# TODO: get rid of these hard coded references to deploy tools.
	var dep = _xcode.project.get_deploy()
	var ios_dep_strat = dep.IOSDeployToolStrategy.new()
	var libimobile_strat = dep.LibimobiledeviceToolStrategy.new()

	var cfg = stc.get_config()
	var v = get_view()
	v.remote_debug = cfg.get_value('xcode/project', 'remote_debug', false)
	v.deploy_tool = cfg.get_value(dep.DEPLOY_CONFIG_SECTION, dep.DEPLOY_TOOL_CONFIG_KEY, libimobile_strat.get_tool_name())
	v.ios_deploy_tool_path = cfg.get_value(ios_dep_strat.get_config_section(), ios_dep_strat.KEY_PATH, ios_dep_strat.get_default_tool_path())
	v.libimobile_tool_path = cfg.get_value(libimobile_strat.get_config_section(), libimobile_strat.KEY_PATH, libimobile_strat.get_default_tool_path())
	v.godot_bin_path = cfg.get_value('xcode/project', 'godot_bin_path', '')
	v.log_level = cfg.get_value('meta', 'log_level', stc.get_logger().get_default_output_level())
	v.log_file = cfg.get_value('meta', 'log_file', '')


func _on_hide():
	# TODO: get rid of these hard coded references to deploy tools.
	var dep = _xcode.project.get_deploy()
	var ios_dep_strat = dep.IOSDeployToolStrategy.new()
	var libimobile_strat = dep.LibimobiledeviceToolStrategy.new()

	var cfg = stc.get_confg()
	var v = get_view()
	cfg.set_value('meta', 'log_level', v.log_level)
	cfg.set_value('meta', 'log_file', v.log_file)
	cfg.set_value('xcode/project', 'remote_debug', v.remote_debug)
	cfg.set_value(dep.DEPLOY_CONFIG_SECTION, dep.DEPLOY_TOOL_CONFIG_KEY, v.deploy_tool)
	cfg.set_value(ios_dep_strat.get_config_section(), ios_dep_strat.KEY_PATH, v.ios_deploy_tool_path)
	cfg.set_value(libimobile_strat.get_config_section(), libimobile_strat.KEY_PATH, v.libimobile_tool_path)
	cfg.set_value('deploy', 'ios_deploy_tool_path', v.ios_deploy_tool_path)
	cfg.set_value('xcode/project', 'godot_bin_path', v.godot_bin_path)
	cfg.save()
