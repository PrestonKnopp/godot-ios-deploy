# _v3/editor_debug_settings.gd
extends '../editor_debug_settings.gd'

func _init(editor_settings).(editor_settings):
	pass

func _get_editor_project_metadata_config_path():
	return _editor_settings.get_project_settings_dir().plus_file('project_metadata.cfg')

func _get_value(key, default):
	var sect = 'debug_options'
	if _editor_settings.has_method('get_project_metadata'):
		# >=3.1 has builtin support for editor project metadata
		return _editor_settings.get_project_metadata(sect, key, false)
	var cfg = _get_editor_project_metadata_config()
	return cfg.get_value(sect, key, false)

func is_remote_debug_enabled():
	return _get_value('run_deploy_remote_debug', false)

func is_debug_collisions_enabled():
	# TODO: fix typo from godot
	return _get_value('run_debug_collisons', false)

func is_debug_navigation_enabled():
	return _get_value('run_debug_navigation', false)
