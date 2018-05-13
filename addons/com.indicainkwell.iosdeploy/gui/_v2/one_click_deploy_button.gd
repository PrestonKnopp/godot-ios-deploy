extends Button


signal mouse_hovering()


var hovering_wait_time = 0.5
var _hovering_time_waited = 0.0


func _init():
	connect('mouse_enter', self, '_on_mouse_enter')
	connect('mouse_exit', self, '_on_mouse_exit')


func _process(d):
	_hovering_time_waited += d
	if _hovering_time_waited > hovering_wait_time:
		emit_signal("mouse_hovering")
		set_process(false)


func _on_mouse_enter():
	set_process(true)


func _on_mouse_exit():
	set_process(false)
	_hovering_time_waited = 0.0