# onboarding_flow.gd
#
# Handles the transition, validation, and population of onboarding screens.
extends AcceptDialog


# ------------------------------------------------------------------------------
#                                      Signals
# ------------------------------------------------------------------------------


signal onboarded(this)
signal populate(this, section, subsection)
signal validate(this, section, subsection, input)


# ------------------------------------------------------------------------------
#                                      Exports
# ------------------------------------------------------------------------------


export(float) var transition_time = 0.25


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var _size_difference = Vector2()


# ------------------------------------------------------------------------------
#                                  Button SetGets
# ------------------------------------------------------------------------------


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


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


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


func _on_control_stack_screen_entering( this, from_screen, screen ):
	"""
	Resizes dialog, enables and disables back button, and sets next button
	to DONE when it is the last screen.
	"""
	get_back_button().set_disabled(screen.index == 0)
	if screen.index + 1 >= this.get_screen_count():
		get_next_button().set_text('DONE')
	else:
		get_next_button().set_text('NEXT')
	resize_for(screen)


func _on_control_stack_draw():
	VisualServer.canvas_item_set_clip(get_node('control_stack').get_canvas_item(), true)
