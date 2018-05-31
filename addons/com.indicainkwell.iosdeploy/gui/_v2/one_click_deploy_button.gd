# one_click_deploy_button.gd
extends Button


signal presenting_hover_menu(this, menu)
signal settings_button_pressed(this)


func _on_mouse_enter():
	if get_node('hover_panel').is_hidden():
		get_node('hover_timer').start()
	else:
		get_node('hover_timer').stop()


func _on_mouse_exit():
	if get_node('hover_panel').is_hidden():
		get_node('hover_timer').stop()
	else:
		get_node('hover_timer').start()


func _on_hover_panel_input_event(e):
	# hack, mouse_exit is emitted when over an active child control
	# within the bounds of target control
	#
	# this will stop hover_timer when any event is received as that means
	# mouse is hovering panel
	if get_node('hover_timer').is_active():
		get_node('hover_timer').stop()


func _on_hover_panel_mouse_enter():
	get_node('hover_timer').stop()


func _on_hover_panel_mouse_exit():
	get_node('hover_timer').start()


func _on_hover_timer_timeout():
	if get_node('hover_panel').is_hidden():
		emit_signal('presenting_hover_menu', self, get_node('hover_panel'))
		get_node('hover_panel').show()
	else:
		get_node('hover_panel').hide()


func _on_settings_button_pressed():
	emit_signal('settings_button_pressed', self)
