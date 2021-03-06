# onboarding_flow.gd
#
# Handles the transition, validation, and population of onboarding screens.
tool
extends AcceptDialog


# ------------------------------------------------------------------------------
#                                      Signals
# ------------------------------------------------------------------------------


signal onboarded(this)
signal populate(this, section)
signal validate(this, section, input)


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const stc = preload('../scripts/static.gd')


enum SECTION {
	PROVISION=0,
	AUTOMANAGE=1,
	TEAM=2,
	DISPLAY_NAME=3,
	BUNDLE_ID=4
}


# ------------------------------------------------------------------------------
#                                      Exports
# ------------------------------------------------------------------------------


# Time it takes to transition from screen to screen
export(float) var transition_time = 0.25
# The colors to draw for section validation
export(Color) var valid_color = Color(0.0, 1.0, 0.0, 0.25)
export(Color) var invalid_color = Color(1.0, 0.0, 0.0, 0.25)


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


# The size diff between the initial size of control_stack and the first screen
var _size_difference = Vector2()
# The validity of section. Indexed by the SECTION enum. i.e.
# _section_validity[0] is PROVISION is validity flag.
var _section_validity = []


# ------------------------------------------------------------------------------
#                                      SetGets
# ------------------------------------------------------------------------------


# -- Button

var next_button setget ,get_next_button
func get_next_button():
	"""
	Get the next button which is also the DONE button.
	"""
	return get_ok()


var back_button setget ,get_back_button
func get_back_button():
	"""
	Get the back button.
	"""
	if back_button == null:
		for node in get_children():
			# I own this, so it's not going to contain
			# the button I'm searching for
			if node.get_owner() != null: continue
			for subnode in node.get_children():
				if subnode.has_method('get_text') and subnode.get_text() == 'BACK':
					back_button = subnode
	return back_button


# -- Inputs

var provision    setget set_provision,    get_provision
var automanaged  setget set_automanaged,  get_automanaged
var team         setget set_team,         get_team
var display_name setget set_display_name, get_display_name
var bundle_id    setget set_bundle_id,    get_bundle_id

# -- Inputs Setters

func set_provision(v):    set_section_value(SECTION.PROVISION, v)
func set_automanaged(v):  set_section_value(SECTION.AUTOMANAGE, v)
func set_team(v):         set_section_value(SECTION.TEAM, v)
func set_display_name(v): set_section_value(SECTION.DISPLAY_NAME, v)
func set_bundle_id(v):    set_section_value(SECTION.BUNDLE_ID, v)

# -- Inputs Getters

func get_provision():    return get_section_value(SECTION.PROVISION)
func get_automanaged():  return get_section_value(SECTION.AUTOMANAGE)
func get_team():         return get_section_value(SECTION.TEAM)
func get_display_name(): return get_section_value(SECTION.DISPLAY_NAME)
func get_bundle_id():    return get_section_value(SECTION.BUNDLE_ID)


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func populate_option_section(section, values=[]):
	"""
	Populate option section with multiple values. The rest of the sections
	can be populated with their respective setter.
	"""
	assert(section in [SECTION.TEAM, SECTION.PROVISION])
	var optbutt = get_section_control(section)
	optbutt.clear()
	for i in range(values.size()):
		var value = values[i]
		optbutt.add_item(value.name)
		optbutt.set_item_metadata(i, value)


func validate(section, valid):
	"""
	Set section validity.
	"""
	var control = get_section_control(section)
	var overlay = get_node('overlay_drawer')
	overlay.over(control, valid_color if valid else invalid_color)
	_section_validity[section] = valid


func is_screen_valid():
	for section in get_screen_sections(get_node('control_stack').screen):
		if _section_validity[section] == false:
			return false
	return true


func get_section_value(section):
	"""
	Returns the value held in `section` control.
	@return Any?
	"""
	var section_control = get_section_control(section)
	if section in [SECTION.PROVISION, SECTION.TEAM]:
		return section_control.get_selected_metadata()
	elif section == SECTION.AUTOMANAGE:
		return section_control.is_pressed()
	elif section in [SECTION.DISPLAY_NAME, SECTION.BUNDLE_ID]:
		return section_control.get_text()


func set_section_value(section, value):
	"""
	Set the `section`'s control value.
	"""
	var section_control = get_section_control(section)
	if section in [SECTION.PROVISION, SECTION.TEAM]:
		for i in range(section_control.get_item_count()):
			var meta = section_control.get_item_metadata(i)
			if meta != null and meta.equals(value):
				section_control.select(i)
				return
		assert(false) # invalid input given
	elif section == SECTION.AUTOMANAGE:
		section_control.set_pressed(value)
	elif section in [SECTION.DISPLAY_NAME, SECTION.BUNDLE_ID]:
		section_control.set_text(value)


func get_section_control(section):
	"""
	Get the `section`'s control.
	@return Control
	"""
	assert(section >= SECTION.PROVISION and section <= SECTION.BUNDLE_ID)
	if section == SECTION.PROVISION:
		return get_node('control_stack/select_provision/profile_optbutt')
	elif section == SECTION.AUTOMANAGE:
		return get_node('control_stack/select_provision/VBoxContainer/automanage_checkbutt')
	elif section == SECTION.TEAM:
		return get_node('control_stack/select_team/team_optbutt')
	elif section == SECTION.DISPLAY_NAME:
		return get_node('control_stack/select_bundle/VBoxContainer/display_name_lineedit')
	elif section == SECTION.BUNDLE_ID:
		return get_node('control_stack/select_bundle/VBoxContainer_1/bundle_id_lineedit')


func get_screen_sections(screen):
	"""
	Get the sections that appear in screen.
	@return [
	"""
	if screen.index == 0:
		return [SECTION.PROVISION, SECTION.AUTOMANAGE]
	elif screen.index == 1:
		return [SECTION.TEAM]
	elif screen.index == 2:
		return [SECTION.DISPLAY_NAME, SECTION.BUNDLE_ID]
	else:
		return []


func resize_for(screen):
	"""
	Resize the this dialog to be the PreferredSize of screen.
	@screen: Screen
	  The screen to resize to
	"""
	var func_get_pos
	var prop_rect_size
	var prop_rect_pos
	if stc.get_version().is2():
		func_get_pos = 'get_pos'
		prop_rect_size = 'rect/size'
		prop_rect_pos = 'rect/pos'
	else:
		func_get_pos = 'get_position'
		prop_rect_size = 'rect_size'
		prop_rect_pos = 'rect_position'


	var tween = get_node('Tween')

	# Looks like in v3 size does not tween well because when new controls
	# are made visible it snaps the parent control size to fit the new
	# controls. Where in v2 the controls will just overlap until a proper
	# size is set.
	var initial_size = get_size()
	var final_size = screen.node.get_node('PreferredSize').size + _size_difference
	tween.interpolate_property(self, prop_rect_size, initial_size, final_size, transition_time, tween.TRANS_SINE, tween.EASE_OUT)
	
	var nearest_control_parent_size
	if get_parent_control() != null:
		nearest_control_parent_size = get_parent_control().get_size()
	else:
		nearest_control_parent_size = get_viewport().get_visible_rect().size
	
	var initial_pos = call(func_get_pos)
	var final_pos = (nearest_control_parent_size / 2 - final_size / 2).floor()
	tween.interpolate_property(self, prop_rect_pos, initial_pos, final_pos, transition_time, tween.TRANS_SINE, tween.EASE_OUT)

	tween.start()


# ------------------------------------------------------------------------------
#                                  Private Methods
# ------------------------------------------------------------------------------


func request_validation(section, value):
	emit_signal('validate', self, section, value)
	get_next_button().set_disabled(not is_screen_valid())


# ------------------------------------------------------------------------------
#                                  Node Callbacks
# ------------------------------------------------------------------------------


func _ready():
	_size_difference = get_rect().size - get_node('control_stack/select_provision').get_rect().size
	_section_validity.resize(SECTION.size())
	get_next_button().set_text('NEXT')
	add_button('BACK', false, 'BACK')


# ------------------------------------------------------------------------------
#                                  Signal Handlers
# ------------------------------------------------------------------------------


# -- AcceptDialog (self)

func _on_confirmed():
	"""
	Pushes next screen and emits onboarded when last screen is confirmed.
	"""
	var stack = get_node('control_stack')
	if get_next_button().get_text() == 'DONE':
		emit_signal('onboarded', self)
		stack.reset()
		return
	stack.push(stack.screen.index + 1)


func _on_custom_action( action ):
	"""
	Pops the stack. Custom action is only BACK.
	"""
	var stack = get_node('control_stack')
	stack.pop()


# -- Control Stack

func _on_control_stack_screen_entering( this, from_screen, screen ):
	"""
	Resizes dialog, enables and disables back button, and sets next button
	to DONE when it is the last screen. Additionally emits populate.
	"""

	# Populate screen sections then validate because sections can depend
	# on other sections in the previous or same screens.
	var screen_sections = get_screen_sections(screen)
	for section in screen_sections:
		emit_signal('populate', self, section)
	for section in screen_sections:
		request_validation(section, get_section_value(section))

	get_back_button().set_disabled(screen.index == 0)
	if screen.index + 1 >= this.get_screen_count():
		get_next_button().set_text('DONE')
	else:
		get_next_button().set_text('NEXT')
	resize_for(screen)


func _on_control_stack_draw():
	VisualServer.canvas_item_set_clip(get_node('control_stack').get_canvas_item(), true)


# -- Input Validation

func _on_profile_optbutt_item_selected( ID ):
	var optbutt = get_node('control_stack/select_provision/profile_optbutt')
	var meta = optbutt.get_selected_metadata()
	request_validation(SECTION.PROVISION, meta)


func _on_automanage_checkbutt_toggled( pressed ):
	request_validation(SECTION.AUTOMANAGE, pressed)


func _on_team_optbutt_item_selected( ID ):
	var optbutt = get_node('control_stack/select_team/team_optbutt')
	var meta = optbutt.get_selected_metadata()
	request_validation(SECTION.TEAM, meta)


func _on_display_name_lineedit_text_changed( text ):
	request_validation(SECTION.DISPLAY_NAME, text)


func _on_bundle_id_lineedit_text_changed( text ):
	request_validation(SECTION.BUNDLE_ID, text)
