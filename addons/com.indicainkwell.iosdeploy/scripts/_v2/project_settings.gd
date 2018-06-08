# project_settings.gd
extends '../project_settings.gd'


func has_setting(setting):
	return Globals.has(setting)


func get_setting(setting):
	return Globals.get(setting)


func set_setting(setting, value):
	Globals.set(setting, value)
