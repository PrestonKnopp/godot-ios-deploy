# plugin_config.gd
extends Object


# ------------------------------------------------------------------------------
#                                      Signals
# ------------------------------------------------------------------------------


signal changed(this, section, key, from_value, to_value)


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const stc = preload('static.gd')


class _N:
	extends Object


# ------------------------------------------------------------------------------
#                                 Private Variables
# ------------------------------------------------------------------------------


var _log = stc.get_logger().make_module_logger(stc.PLUGIN_DOMAIN + '.config')
var _config = ConfigFile.new()


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _init():
	if _config.load(stc.get_data_path('config.cfg')) != OK:
		_log.info('unable to load config')
	
	var cfg_version = _config.get_value('meta', 'version', -1)
	if cfg_version != stc.CONFIG_VERSION:
		# TODO: implement config versioning
		_log.verbose('Differing config version. Update cfg here.')
		_log.verbose('Changing config version from %s to %s' %
				[str(cfg_version), stc.CONFIG_VERSION])
		_config.set_value('meta', 'version', stc.CONFIG_VERSION)


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func set_value(section, key, value):
	var old_value = get_value(section, key)
	_config.set_value(section, key, value)
	_log.verbose('Set: %s/%s = %s' % [section, key, value])
	emit_signal('changed', self, section, key, old_value, value)


func get_value(section, key, default=_N):
	# Use _N object so that default can be null without throwing error.
	if typeof(default) == TYPE_NIL:
		default = _N
	var value = _config.get_value(section, key, default)
	_log.verbose('Get: %s/%s = %s' % [section, key, value])
	if typeof(value) == TYPE_OBJECT and value == _N:
		return null
	return value


func has_section(section):
	return _config.has_section(section)


func has_section_key(section, key):
	return _config.has_section_key(section, key)


func save():
	_log.info('saving')
	var err = _config.save(stc.get_data_path('config.cfg'))
	if err != OK:
		_log.error('Error<%s>: unable to save config' % err)
