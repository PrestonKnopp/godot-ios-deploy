# onboarding_flow.gd
#
# Handles the transition, validation, and population of onboarding screens.
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


const SECTION = {
	PROVISION=0,
	AUTOMANAGE=1,
	TEAM=2,
	DISPLAY_NAME=3,
	BUNDLE_ID=4
}


# ------------------------------------------------------------------------------
#                                      Exports
# ------------------------------------------------------------------------------


export(float) var transition_time = 0.25
export(Color) var valid_color = Color(0.0, 1.0, 0.0, 0.25)
export(Color) var invalid_color = Color(1.0, 0.0, 0.0, 0.25)


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var _size_difference = Vector2()


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

var provision setget set_provision,get_provision
var automanaged setget set_automanaged,get_automanaged
var team setget set_team,get_team
var display_name setget set_display_name,get_display_name
var bundle_id setget set_bundle_id,get_bundle_id

# -- Inputs Setters

func set_provision(v):
	var optbutt = get_section_control(SECTION.PROVISION)
	for i in optbutt.get_item_count():
		var meta = optbutt.get_item_metadata(i)
		if meta == v:
			optbutt.select(i)
			return
	assert(false)
func set_automanaged(v):
	get_section_control(SECTION.AUTOMANAGE).set_pressed(v)
func set_team(v):
	var optbutt = get_section_control(SECTION.TEAM)
	for i in optbutt.get_item_count():
		var meta = optbutt.get_item_metadata(i)
		if meta == v:
			optbutt.select(i)
			return
	assert(false)
func set_display_name(v):
	get_section_control(SECTION.DISPLAY_NAME).set_text(v)
func set_bundle_id(v):
	get_section_control(SECTION.BUNDLE_ID).set_text(v)

# -- Inputs Getters

func get_provision():
	return get_section_control(SECTION.PROVISION).get_selected_metadata()
func get_automanaged():
	return get_section_control(SECTION.AUTOMANAGE).is_pressed()
func get_team():
	return get_section_control(SECTION.TEAM).get_selected_metadata()
func get_display_name():
	return get_section_control(SECTION.DISPLAY_NAME).get_text()
func get_bundle_id():
	return get_section_control(SECTION.BUNDLE_ID).get_text()


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
	Set visually the validity of a section.
	"""
	var control = get_section_control(section)
	var overlay = get_node('overlay_drawer')
	overlay.over(control, valid_color if valid else invalid_color)


func get_section_control(section):
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
	if screen.index == 0:
		return [SECTION.PROVISION, SECTION.AUTOMANAGE]
	elif screen.index == 2:
		return [SECTION.TEAM]
	elif screen.index == 3:
		return [SECTION.DISPLAY_NAME, SECTION.BUNDLE_ID]
	else:
		return []


func resize_for(screen):
	"""
	Resize the this dialog to be the PreferredSize of screen.
	@screen: Screen
	  The screen to resize to
	"""
	var tween = get_node('Tween')

	var initial_size = get_size()
	var final_size = screen.node.get_node('PreferredSize').size + _size_difference
	tween.interpolate_property(self, 'rect/size', initial_size, final_size, transition_time, tween.TRANS_SINE, tween.EASE_OUT)
	
	var nearest_control_parent_size
	if get_parent_control() != null:
		nearest_control_parent_size = get_parent_control().get_size()
	else:
		nearest_control_parent_size = get_viewport().get_visible_rect().size
	
	var initial_pos = get_pos()
	var final_pos = (nearest_control_parent_size / 2 - final_size / 2).floorf()
	tween.interpolate_property(self, 'rect/pos', initial_pos, final_pos, transition_time, tween.TRANS_SINE, tween.EASE_OUT)

	tween.start()


# ------------------------------------------------------------------------------
#                                  Node Callbacks
# ------------------------------------------------------------------------------


func _ready():
	_size_difference = get_rect().size - get_node('control_stack/select_provision').get_rect().size
	get_next_button().set_text('NEXT')
	add_button('BACK', false, 'BACK')
	call_deferred('popup_centered')


# ------------------------------------------------------------------------------
#                                  Signal Handlers
# ------------------------------------------------------------------------------


# -- AcceptDialog (self)

func _on_confirmed():
	"""
	Pushes next screen and emits onboarded when last screen is confirmed.
	"""
	if get_next_button().get_text() == 'DONE':
		emit_signal('onboarded', self)
		return
	var stack = get_node('control_stack')
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
	for section in get_screen_sections(screen):
		emit_signal('populate', self, section)
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
	emit_signal('validate', self, SECTION.PROVISION, meta)


func _on_automanage_checkbutt_toggled( pressed ):
	emit_signal('validate', self, SECTION.AUTOMANAGE, pressed)


func _on_team_optbutt_item_selected( ID ):
	var optbutt = get_node('control_stack/select_team/team_optbutt')
	var meta = optbutt.get_selected_metadata()
	emit_signal('validate', self, SECTION.TEAM, meta)


func _on_display_name_lineedit_text_changed( text ):
	emit_signal('validate', self, SECTION.DISPLAY_NAME, text)


func _on_bundle_id_lineedit_text_changed( text ):
	emit_signal('validate', self, SECTION.BUNDLE_ID, text)
