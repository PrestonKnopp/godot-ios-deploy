# editor_debug_settings.gd
tool
extends Reference

const stc = preload('static.gd')

var remote_debug setget ,is_remote_debug_enabled
var debug_collisions setget ,is_debug_collisions_enabled
var debug_navigation setget ,is_debug_navigation_enabled

var _log = stc.get_logger().make_module_logger(stc.PLUGIN_DOMAIN + '.editor-debug-settings')
var _editor_settings

func _init(editor_settings):
	"""
	@editor_settings: EditorSettings
	  Needs editor settings object from EditorPlugin to function.
	"""
	_editor_settings = editor_settings

func _get_editor_project_metadata_config():
	var p = _get_editor_project_metadata_config_path()
	var cfg = ConfigFile.new()
	var err = cfg.load(p)
	if err != OK:
		_log.debug('Error<%s> unable to load editor project metadata at %s' % [err,p])
	return cfg

func _get_editor_project_metadata_config_path():
	pass

func is_remote_debug_enabled():
	return false

func is_debug_collisions_enabled():
	return false

func is_debug_navigation_enabled():
	return false
