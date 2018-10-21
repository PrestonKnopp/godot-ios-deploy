# settings_menu.gd
#
# Interface to settings_menu.tscn.
tool
extends WindowDialog

#signal populate(this, section)
#signal validate(this, section)
#signal edited(this, section)
signal pressed(this, press_section)

enum SECTION {
	REMOTE_DEBUG,
	LOG_LEVEL,
	LOG_FILE,
	IOSDEPLOY,
	GODOT_BIN
}

enum PRESS_SECTION {
	ONBOARDING_FLOW_OPEN,
	XCODE_PROJ_COPY,
	XCODE_PROJ_OPEN
}


# -- Inputs

var remote_debug    setget set_remote_debug,    get_remote_debug
var log_level       setget set_log_level,       get_log_level
var log_file        setget set_log_file,        get_log_file
var ios_deploy_path setget set_ios_deploy_path, get_ios_deploy_path
var godot_bin_path  setget set_godot_bin_path,  get_godot_bin_path

# -- Inputs Setters

func set_remote_debug(v):    set_section_value(REMOTE_DEBUG, v)
func set_log_level(v):       set_section_value(LOG_LEVEL, v)
func set_log_file(v):        set_section_value(LOG_FILE, v)
func set_ios_deploy_path(v): set_section_value(IOSDEPLOY, v)
func set_godot_bin_path(v):  set_section_value(GODOT_BIN, v)

# -- Inputs Getters

func get_remote_debug():    return get_section_value(REMOTE_DEBUG)
func get_log_level():       return get_section_value(LOG_LEVEL)
func get_log_file():        return get_section_value(LOG_FILE)
func get_ios_deploy_path(): return get_section_value(IOSDEPLOY)
func get_godot_bin_path():  return get_section_value(GODOT_BIN)


func get_section_value(section):
	"""
	Returns the value held in `section` control.
	@return Any?
	"""
	var section_control = get_section_control(section)
	if section == REMOTE_DEBUG:
		return section_control.is_pressed()
	elif section == LOG_LEVEL:
		return section_control.get_selected()
	elif section in [IOSDEPLOY, GODOT_BIN, LOG_FILE]:
		return section_control.get_text()


func set_section_value(section, value):
	"""
	Set the `section`'s control value.
	"""
	var section_control = get_section_control(section)
	if section == REMOTE_DEBUG:
		return section_control.set_pressed(value)
	elif section == LOG_LEVEL:
		return section_control.select(value)
	elif section in [IOSDEPLOY, GODOT_BIN, LOG_FILE]:
		return section_control.set_text(value)


func get_section_control(section):
	"""
	Get the `section`'s control.
	@return Control
	"""
	assert(section >= REMOTE_DEBUG and section <= GODOT_BIN)
	if section == REMOTE_DEBUG:
		return find_node('remote_debug_butt')
	elif section == LOG_LEVEL:
		return find_node('log_level_opt')
	elif section == LOG_FILE:
		return find_node('logfile_path')
	elif section == IOSDEPLOY:
		return find_node('iosdeploy_tool_path')
	elif section == GODOT_BIN:
		return find_node('godot_bin_path')


func _on_open_onboarding_flow_butt_pressed():
	emit_signal('pressed', self, ONBOARDING_FLOW_OPEN)


func _on_open_xcproj_butt_pressed():
	emit_signal('pressed', self, XCODE_PROJ_OPEN)


func _on_copy_xcproj_butt_pressed():
	emit_signal('pressed', self, XCODE_PROJ_COPY)