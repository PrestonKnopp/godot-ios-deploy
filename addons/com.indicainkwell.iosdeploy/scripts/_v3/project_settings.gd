# project_settings.gd
extends '../project_settings.gd'


func has_setting(setting):
	return ProjectSettings.has_setting(setting)


func get_setting(setting):
	return ProjectSettings.get_setting(setting)


func set_setting(setting, value):
	ProjectSettings.set_setting(setting, value)

