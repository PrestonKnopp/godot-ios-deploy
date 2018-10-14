# project_settings.gd
extends '../project_settings.gd'


static func has_setting(setting):
	return Globals.has(setting)


static func get_setting(setting):
	return Globals.get(setting)


static func set_setting(setting, value):
	Globals.set(setting, value)


static func has_metadata(key):
	return Globals.has_meta(key)


static func set_metadata(key, value):
	Globals.set_meta(key, value)


static func get_metadata(key):
	return Globals.get_meta(key)
