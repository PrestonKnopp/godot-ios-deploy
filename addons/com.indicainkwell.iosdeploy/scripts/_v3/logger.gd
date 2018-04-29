# logger.gd
extends '../logger.gd'


func _initialize():
	._initialize()
	ProjectSettings.set_settings(stc.LOGGER_DOMAIN, self)

func cleanup():
	.cleanup()
	ProjectSettings.clear(stc.LOGGER_DOMAIN)

static func get_logger():
	if ProjectSettings.has_setting(stc.LOGGER_DOMAIN):
		return

static func has_logger():
	return ProjectSettings.has_setting(stc.LOGGER_DOMAIN)

static func get_logger():
	return ProjectSettings.get_setting(stc.LOGGER_DOMAIN)
