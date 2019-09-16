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
	DEPLOY_TOOL,
	IOSDEPLOY_TOOL,
	LIBIMOBILE_TOOL,
	GODOT_BIN
}

enum PRESS_SECTION {
	ONBOARDING_FLOW_OPEN,
	XCODE_PROJ_COPY,
	XCODE_PROJ_OPEN,
	XCODE_PROJ_FILL_EXPORT
}


# -- Inputs

var remote_debug         setget set_remote_debug,         get_remote_debug
var log_level            setget set_log_level,            get_log_level
var log_file             setget set_log_file,             get_log_file
var deploy_tool          setget set_deploy_tool,          get_deploy_tool
var ios_deploy_tool_path setget set_ios_deploy_tool_path, get_ios_deploy_tool_path
var libimobile_tool_path setget set_libimobile_tool_path, get_libimobile_tool_path
var godot_bin_path       setget set_godot_bin_path,       get_godot_bin_path

# -- Inputs Setters

func set_remote_debug(v):         set_section_value(SECTION.REMOTE_DEBUG, v)
func set_log_level(v):            set_section_value(SECTION.LOG_LEVEL, v)
func set_log_file(v):             set_section_value(SECTION.LOG_FILE, v)
func set_deploy_tool(v):          set_section_value(SECTION.DEPLOY_TOOL, v)
func set_ios_deploy_tool_path(v): set_section_value(SECTION.IOSDEPLOY_TOOL, v)
func set_libimobile_tool_path(v): set_section_value(SECTION.LIBIMOBILE_TOOL, v)
func set_godot_bin_path(v):       set_section_value(SECTION.GODOT_BIN, v)

# -- Inputs Getters

func get_remote_debug():         return get_section_value(SECTION.REMOTE_DEBUG)
func get_log_level():            return get_section_value(SECTION.LOG_LEVEL)
func get_log_file():             return get_section_value(SECTION.LOG_FILE)
func get_deploy_tool():          return get_section_value(SECTION.DEPLOY_TOOL)
func get_ios_deploy_tool_path(): return get_section_value(SECTION.IOSDEPLOY_TOOL)
func get_libimobile_tool_path(): return get_section_value(SECTION.LIBIMOBILE_TOOL)
func get_godot_bin_path():       return get_section_value(SECTION.GODOT_BIN)


func get_section_value(section):
	"""
	Returns the value held in `section` control.
	@return Any?
	"""
	var section_control = get_section_control(section)
	if section == SECTION.REMOTE_DEBUG:
		return section_control.is_pressed()
	elif section in [SECTION.LOG_LEVEL, SECTION.DEPLOY_TOOL]:
		return section_control.get_selected()
	elif section in [SECTION.IOSDEPLOY_TOOL, SECTION.LIBIMOBILE_TOOL, SECTION.GODOT_BIN, SECTION.LOG_FILE]:
		return section_control.get_text()


func set_section_value(section, value):
	"""
	Set the `section`'s control value.
	"""
	var section_control = get_section_control(section)
	if section == SECTION.REMOTE_DEBUG:
		return section_control.set_pressed(value)
	elif section == SECTION.LOG_LEVEL:
		return section_control.select(value)
	elif section == SECTION.DEPLOY_TOOL:
		for i in section_control.get_item_count():
			if value == section_control.get_item_text(i):
				return section_control.select(i)
	elif section in [SECTION.IOSDEPLOY_TOOL, SECTION.LIBIMOBILE_TOOL, SECTION.GODOT_BIN, SECTION.LOG_FILE]:
		return section_control.set_text(value)


func get_section_control(section):
	"""
	Get the `section`'s control.
	@return Control
	"""
	assert(section >= SECTION.REMOTE_DEBUG and section <= SECTION.GODOT_BIN)
	if section == SECTION.REMOTE_DEBUG:
		return find_node('remote_debug_butt')
	elif section == SECTION.LOG_LEVEL:
		return find_node('log_level_opt')
	elif section == SECTION.LOG_FILE:
		return find_node('logfile_path')
	elif section == SECTION.DEPLOY_TOOL:
		return find_node('deploy_tool_opt')
	elif section == SECTION.IOSDEPLOY_TOOL:
		return find_node('iosdeploy_tool_path')
	elif section == SECTION.LIBIMOBILE_TOOL:
		return find_node('libimobile_tool_path')
	elif section == SECTION.GODOT_BIN:
		return find_node('godot_bin_path')


func _on_open_onboarding_flow_butt_pressed():
	emit_signal('pressed', self, PRESS_SECTION.ONBOARDING_FLOW_OPEN)


func _on_open_xcproj_butt_pressed():
	emit_signal('pressed', self, PRESS_SECTION.XCODE_PROJ_OPEN)


func _on_copy_xcproj_butt_pressed():
	emit_signal('pressed', self, PRESS_SECTION.XCODE_PROJ_COPY)


func _on_fill_godot_export_presets_pressed():
	emit_signal('pressed', self, PRESS_SECTION.XCODE_PROJ_FILL_EXPORT)

