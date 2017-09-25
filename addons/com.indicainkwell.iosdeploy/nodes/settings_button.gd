# settings_button.gd
tool
extends WindowDialog

# Settings should have only one depth section -> key

onready var _tree = get_node('Tree')
onready var _file = get_node('FileDialog')
onready var _config_node = get_node('config')


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _ready():
	_tree.set_columns(2)


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func get_config():
	return _config_node.get_config()

# ------------------------------------------------------------------------------
#                                     Handlers
# ------------------------------------------------------------------------------


func _on_tree_item_selected():
	print('Tree Item Selected')
	var item = _tree.get_selected()
	var col = _tree.get_selected_column()
	if col == 1 and item.get_text(0) == 'path':
		_file.set_current_path(item.get_metadata(col))
		_file.popup_centered_ratio()

func _on_file_dialog_xcodeproj_chosen(path):
	var item = _tree.get_selected()
	print('Path Chosen: ', path)
	item.set_metadata(1, path)
	item.set_text(1, path.get_file())

func _on_settings_window_about_to_show():
	print('Settings about to show')
	var root = _tree.create_item()
	root.set_text(0, 'Settings')

	var config = get_config()
	if config:
		var sections = config.get_sections()
		for section in sections:
			var section_item = _tree.create_item(root)
			section_item.set_text(0, section)
			for key in config.get_section_keys(section):
				var key_value = config.get_value(section, key, '')
				var key_item = _tree.create_item(section_item)
				key_item.set_text(0, key)
				if key == 'path':
					key_item.set_metadata(1, key_value)
					key_item.set_text(1, key_value.get_file())
					key_item.set_selectable(1, true)
				else:
					key_item.set_text(1, key_value)
					key_item.set_editable(1, true)


func _on_settings_window_popup_hide():
	var root = _tree.get_root()
	
	var config = get_config()
	if config:
		var item = root.get_children()
		while item:
			var section = item.get_text(0)
			var child = item.get_children()
			while child:
				var key = child.get_text(0)
				var key_value = child.get_text(1)
				if key == 'path':
					key_value = child.get_metadata(1)
				config.set_value(section, key, key_value)
				child = child.get_next()
			item = item.get_next()
		
		_config_node.save_config()
	
	_tree.clear()
