# one_click_deploy_button.gd
tool
extends Button


signal presenting_hover_menu(this)
signal settings_button_pressed(this)


const stc = preload('../scripts/static.gd')



func check_is_hidden(canvas_item):
	if stc.get_version().is2():
		return canvas_item.is_hidden()
	else:
		return not canvas_item.is_visible()


func _place_panel(panel):
	# have panel popup to the left of button so it isn't clipped
	# offscreen.
	if stc.get_version().is2():
		var newpos = get_global_pos()
		newpos.x -= panel.get_size().x - get_size().x
		newpos.y = panel.get_pos().y
		panel.set_pos(newpos)
	else:
		var newpos = self.rect_global_position
		newpos.x -= panel.rect_size.x - self.rect_size.x
		newpos.y = panel.rect_position.y
		panel.rect_position = newpos


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


func _draw_build_progress_overlay():
	var bar = get_node('build_progress_bar')

	var r = get_rect()
	if stc.get_version().is2():
		r.size.x *= bar.get_unit_value()
		r.pos = Vector2()
	else:
		r.size.x *= bar.ratio
		r.position = Vector2()

	var c = ColorN('white')
	c.a = 0.4
	draw_rect(r, c)


func _draw():
	_draw_build_progress_overlay()


func _on_build_progress_bar_changed():
	update()


func _on_mouse_enter():
	if check_is_hidden(get_node('hover_panel')):
		get_node('hover_timer').start()
	else:
		get_node('hover_timer').stop()


func _on_mouse_exit():
	if check_is_hidden(get_node('hover_panel')):
		get_node('hover_timer').stop()
	else:
		get_node('hover_timer').start()


func _on_hover_panel_input_event(e):
	# hack, mouse_exit is emitted when over an active child control
	# within the bounds of target control
	#
	# this will stop hover_timer when any event is received as that means
	# mouse is hovering panel
	if stc.get_version().is2():
		if get_node('hover_timer').is_active():
			get_node('hover_timer').stop()
	else:
		if not get_node('hover_timer').is_stopped():
			get_node('hover_timer').stop()


func _on_hover_panel_mouse_enter():
	get_node('hover_timer').stop()


func _on_hover_panel_mouse_exit():
	get_node('hover_timer').start()


func _on_hover_timer_timeout():
	if check_is_hidden(get_node('hover_panel')):
		emit_signal('presenting_hover_menu', self)

		var hover_panel = get_node('hover_panel')
		hover_panel.set_as_toplevel(true)
		_place_panel(hover_panel)
		hover_panel.show()
	else:
		get_node('hover_panel').hide()


func _on_settings_button_pressed():
	emit_signal('settings_button_pressed', self)
