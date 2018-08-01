# overlay_drawer.gd
tool
extends Node


func over(control, with_color):
	"""
	Draw an overlay over control with color.
	"""
	if control.is_connected('draw', self, '_on_control_draw'):
		# disconnect in case with_color has changed
		control.disconnect('draw', self, '_on_control_draw')
	control.connect('draw', self, '_on_control_draw', [control, with_color])
	control.update()


func remove(control):
	"""
	Remove overlay from control.
	"""
	if control.is_connected('draw', self, '_on_control_draw'):
		control.disconnect('draw', self, '_on_control_draw')
		control.update()


func _on_control_draw(control, color):
	control.draw_rect(Rect2(Vector2(), control.get_size()), color)
