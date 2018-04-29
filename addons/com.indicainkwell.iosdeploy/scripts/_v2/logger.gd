# logger.gd
extends '../logger.gd'


func _initialize():
	._initialize()
	Globals.set(stc.LOGGER_DOMAIN, self)
	Globals.set_persisting(stc.LOGGER_DOMAIN, false)

func cleanup():
	.cleanup()
	Globals.clear(stc.LOGGER_DOMAIN)

static func has_logger():
	return Globals.has(stc.LOGGER_DOMAIN)

static func get_logger():
	return Globals.get(stc.LOGGER_DOMAIN)
