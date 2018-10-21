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
	if press_section == view.ONBOARDING_FLOW_OPEN:
		get_parent().get_menu().popup_centered()
		_log.debug('opened onboarding flow')
	elif press_section == view.XCODE_PROJ_COPY:
		OS.set_clipboard(_xcode.project.get_xcodeproj_path())
		_log.debug('copied xcodeproj path to clipboard')
	elif press_section == view.XCODE_PROJ_OPEN:
		OS.shell_open('file://' + _xcode.project.get_path())
		_log.debug('opened xcodeproj folder with fs')


func _on_about_to_show():
	var v = get_view()
	v.remote_debug = stc.get_config().get_value('xcode/project', 'remote_debug', false)
	v.ios_deploy_tool_path = stc.get_config().get_value('deploy', 'ios_deploy_tool_path', stc.DEFAULT_IOSDEPLOY_TOOL_PATH)
	v.godot_bin_path = stc.get_config().get_value('deploy', 'godot_bin_path', '')
	v.log_level = stc.get_config().get_value('meta', 'log_level', stc.get_logger().get_default_output_level())
	v.log_file = stc.get_config().get_value('meta', 'log_file', '')


func _on_hide():
	var v = get_view()
	stc.get_config().set_value('xcode/project', 'remote_debug', v.remote_debug)
	stc.get_config().set_value('deploy', 'ios_deploy_tool_path', v.ios_deploy_tool_path)
	stc.get_config().set_value('deploy', 'godot_bin_path', v.godot_bin_path)
	stc.get_config().set_value('meta', 'log_level', v.log_level)
	stc.get_config().set_value('meta', 'log_file', v.log_file)
	stc.get_config().save()
