# deploy_settings_menu.gd
#
# Give the ui suggestions for the user by using the populate_* api.
# Fill in the groups with the fill_* api. Should be done after calling
# populate_*. Otherwise, if ui is not already populated, it will have no effect.
tool
extends Panel


signal request_fill(this)
signal request_populate(this)

signal edited_team(this, to)
signal edited_provision(this, to)
signal edited_bundle_id(this, to)
signal finished_editing(this)


var _first_draw = false


onready var _ctnt = get_node('content_container/VBoxContainer')
onready var _bdldisp = _ctnt.get_node('identifier_group/bundle_group/bundle_display_name')
onready var _bdlid = _ctnt.get_node('identifier_group/bundle_group/bundle_id')
onready var _toptbutt = _ctnt.get_node('identifier_group/identity_group/team_name')
onready var _automngchk = _ctnt.get_node('identifier_group/identity_group/automanage_provision')
onready var _poptbutt = _ctnt.get_node('identifier_group/identity_group/provision_id')
onready var _devlist = _ctnt.get_node('devices_group/devices_list')


# ------------------------------------------------------------------------------
#                               Retrieving User Input
# ------------------------------------------------------------------------------


func get_bundle_group():
	return {
		display = _bdldisp.get_text(),
		id = _bdlid.get_text(),
	}


func get_identity_group():
	return {
		team = _toptbutt.get_selected_metadata(),
		automanaged = _automngchk.is_pressed(),
		provision = _poptbutt.get_selected_metadata(),
	}


func get_active_devices():
	return _devlist.get_active()


# ------------------------------------------------------------------------------
#                             Populating with new data
# ------------------------------------------------------------------------------


func populate_teams(teams):
	_toptbutt.clear()
	for i in range(teams.size()):
		_toptbutt.add_item(teams[i].name)
		_toptbutt.set_item_metadata(i, teams[i])


func populate_provisions(provisions):
	_poptbutt.clear()
	for i in range(provisions.size()):
		_poptbutt.add_item(provisions[i].name)
		_poptbutt.set_item_metadata(i, provisions[i])


func populate_devices(devices):
	_devlist.populate(devices)


# ------------------------------------------------------------------------------
#                                Filling Stored Data
# ------------------------------------------------------------------------------


func fill_bundle_group(display_name, id):
	_bdldisp.set_text(display_name if display_name != null else '')
	_bdlid.set_text(id if id != null else '')


func fill_identity_group(team, automanaged, provision):
	_automngchk.set_pressed(automanaged)
	if team != null:
		for i in range(_toptbutt.get_item_count()):
			var meta = _toptbutt.get_item_metadata(i)
			if meta.name == team.name and meta.id == team.id:
				_toptbutt.select(i)
				break
	if provision != null:
		for i in range(_poptbutt.get_item_count()):
			var meta = _poptbutt.get_item_metadata(i)
			if meta.name == provision.name and meta.id == provision.id:
				_poptbutt.select(i)
				break


func fill_devices_group(devices=[]):
	_devlist.set_active(devices)


# ------------------------------------------------------------------------------
#                               [In]validating Input
# ------------------------------------------------------------------------------


func invalidate_provision():
	print('Invalidating Provision')
	_poptbutt.add_style_override('normal', preload('invalid_sbx.tres'))


func invalidate_team():
	print('Invalidating Team')
	_toptbutt.add_style_override('normal', preload('invalid_sbx.tres'))


func invalidate_bundle_id():
	print('Invalidating Bundleid')
	_bdlid.add_style_override('normal', preload('invalid_sbx.tres'))


func reset_validity():
	# get_stylebox can fetch default theme values by their type name
	# that's what the 'type' param means.
	
	var get_type_func = 'get_type' if Node.new().has_method('get_type')\
	                               else 'get_class'
	for control in [_bdlid, _poptbutt, _toptbutt]:
		var sbx = get_stylebox('normal', control.call(get_type_func))
		control.add_style_override('normal', sbx)



# ------------------------------------------------------------------------------
#                                     Callbacks
# ------------------------------------------------------------------------------


func _on_toptbutt_item_selected(id):
	reset_validity()
	emit_signal('edited_team', self, _toptbutt.get_item_metadata(id))


func _on_poptbutt_item_selected(id):
	reset_validity()
	emit_signal('edited_provision', self, _poptbutt.get_item_metadata(id))


func _on_bdlid_text_changed(new_text):
	reset_validity()
	emit_signal('edited_bundle_id', self, new_text)


func _on_deploy_settings_menu_visibility_changed():
	# hacky: menu_visibility_changed emits twice the first time it becomes
	# visible. Skip the first extra signal.
	if not _first_draw:
		_first_draw = true
		return
	
	if is_hidden():
		emit_signal('finished_editing', self)
	else:
		emit_signal('request_populate', self)
		emit_signal('request_fill', self)
