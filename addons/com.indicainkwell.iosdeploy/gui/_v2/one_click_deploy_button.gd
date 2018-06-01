# one_click_deploy_button.gd
extends Button


signal presenting_hover_menu(this)
signal settings_button_pressed(this)


func update_build_progress(percent, status=null, finished=false):
	var tween = get_node('build_progress_tweener')
	var bar = get_node('build_progress_bar')
	bar.share(get_node('hover_panel/build_progress_bar'))

	if status != null:
		set_build_status(status)

	tween.stop_all()
	if finished:
		bar.set_value(0.0)
		bar.hide()
	else:
		tween.interpolate_method(bar, 'set_value', bar.get_value(), percent * 100.0, 0.5, 0, 0)
		tween.start()


func set_build_status(status):
	get_node('hover_panel/build_progress_bar/HBoxContainer/build_status').set_text(status)


func set_project_valid(valid):
	get_node('hover_panel/HBoxContainer/project_valid').set_pressed(valid)


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
		emit_signal('presenting_hover_menu', self)
		get_node('hover_panel').show()
		get_node('build_progress_bar').hide()
	else:
		get_node('hover_panel').hide()
		if get_node('build_progress_bar').get_value() > 0.0:
			get_node('build_progress_bar').show()


func _on_settings_button_pressed():
	emit_signal('settings_button_pressed', self)
