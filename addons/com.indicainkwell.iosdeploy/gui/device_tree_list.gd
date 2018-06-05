tool
extends Tree


var _root = create_item()


func _init():
	set_hide_root(true)


func _create_device_item():
	var t = create_item(_root)
	t.set_cell_mode(0, t.CELL_MODE_CHECK)
	t.set_editable(0, true)
	return t


func clear():
	.clear()
	_root = create_item()


func populate(devices):
	clear()
	for device in devices:
		var item = _create_device_item()
		item.set_text(0, device.name)
		item.set_metadata(0, device)


func set_active(devices):
	var child = _root.get_children()
	while child != null:
		var meta = child.get_metadata(0)
		for device in devices:
			if device.id == meta.id:
				child.set_checked(0, true)
				break
		child = child.get_next()


func get_active():
	var res = []
	var child = _root.get_children()
	while child != null:
		if child.is_checked(0):
			res.append(child.get_metadata(0))
		child = child.get_next()
	return res
