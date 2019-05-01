# project_settings.gd
extends '../project_settings.gd'


static func has_setting(setting):
	return ProjectSettings.has_setting(setting)


static func get_setting(setting):
	return ProjectSettings.get_setting(setting)


static func set_setting(setting, value):
	ProjectSettings.set_setting(setting, value)


static func has_metadata(key):
	return ProjectSettings.has_meta(key)


static func set_metadata(key, value):
	ProjectSettings.set_meta(key, value)


static func get_metadata(key):
	return ProjectSettings.get_meta(key)
