# deploy_settings_menu.gd
#
# Give the ui suggestions for the user by using the populate_* api.
# Fill in the groups with the fill_* api. Should be done after calling
# populate_*. Otherwise, if ui is not already populated, it will have no effect.
tool
extends Popup


signal request_fill(this)
signal request_populate(this)

signal edited_team(this, to)
signal edited_provision(this, to)
signal edited_bundle_id(this, to)
signal finished_editing(this)


const stc = preload('../scripts/static.gd')


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
	_toptbutt.add_item('None')
	_toptbutt.set_item_metadata(0, null)
	for i in range(teams.size()):
		_toptbutt.add_item(teams[i].name)
		_toptbutt.set_item_metadata(i + 1, teams[i])


func populate_provisions(provisions):
	_poptbutt.clear()
	_poptbutt.add_item('None')
	_poptbutt.set_item_metadata(0, null)
	for i in range(provisions.size()):
		_poptbutt.add_item(provisions[i].name)
		_poptbutt.set_item_metadata(i + 1, provisions[i])


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
	for arr in [[team, _toptbutt], [provision, _poptbutt]]:
		if arr[0] == null:
			continue
		for i in range(1, arr[1].get_item_count()):
			var meta = arr[1].get_item_metadata(i)
			if meta.name == arr[0].name and meta.id == arr[0].id:
				arr[1].select(i)
				break


func fill_devices_group(devices=[]):
	_devlist.set_active(devices)


# ------------------------------------------------------------------------------
#                               [In]validating Input
# ------------------------------------------------------------------------------


func _invalidate(control):
	if control.is_connected('draw', self, '_draw_invalid'):
		return
	control.connect('draw', self, '_draw_invalid', [control])
	control.update()


func _validate(control):
	if control.is_connected('draw', self, '_draw_invalid'):
		control.disconnect('draw', self, '_draw_invalid')
		control.update()


func invalidate_provision():
	print('Invalidating Provision')
	_invalidate(_poptbutt)


func invalidate_team():
	print('Invalidating Team')
	_invalidate(_toptbutt)


func invalidate_bundle_id():
	print('Invalidating Bundleid')
	_invalidate(_bdlid)


func validate_provision():
	print('Validating Provision')
	_validate(_poptbutt)


func validate_team():
	print('Validating Team')
	_validate(_toptbutt)


func validate_bundle_id():
	print('Validating Bundleid')
	_validate(_bdlid)


func reset_validity():
	for control in [_bdlid, _poptbutt, _toptbutt]:
		control.update()


func _draw_invalid(control):
	var c = ColorN('red')
	c.a = 0.1
	control.draw_rect(Rect2(Vector2(), control.get_rect().size), c)


# ------------------------------------------------------------------------------
#                                     Callbacks
# ------------------------------------------------------------------------------


func _on_toptbutt_item_selected(id):
	emit_signal('edited_team', self, _toptbutt.get_item_metadata(id))
	reset_validity()


func _on_poptbutt_item_selected(id):
	emit_signal('edited_provision', self, _poptbutt.get_item_metadata(id))
	reset_validity()


func _on_bdlid_text_changed(new_text):
	emit_signal('edited_bundle_id', self, new_text)
	reset_validity()


func _on_about_to_show():
	emit_signal('request_populate', self)
	emit_signal('request_fill', self)


func _on_popup_hide():
	emit_signal('finished_editing', self)
