# deploy_settings_menu.gd
#
# Give the ui suggestions for the user by using the populate_* api.
# Fill in the groups with the fill_* api. Should be done after calling
# populate_*. Otherwise, if ui is not already populated, it will have no effect.
tool
extends Panel


signal request_fill(this)
signal request_populate(this)
signal finished_editing(this)


onready var _ctnt = get_node('content_container/VBoxContainer')
onready var _bdldisp = _ctnt.get_node('identifier_group/bundle_group/bundle_display_name')
onready var _bdlid = _ctnt.get_node('identifier_group/bundle_group/bundle_id')
onready var _toptbutt = _ctnt.get_node('identifier_group/identity_group/team_name')
onready var _automngchk = _ctnt.get_node('identifier_group/identity_group/automanage_provision')
onready var _poptbutt = _ctnt.get_node('identifier_group/identity_group/provision_id')
onready var _devlist = _ctnt.get_node('devices_group/devices_list')


func _ready():
	pass


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
	_bdldisp.set_text(display_name)
	_bdlid.set_text(id)


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
#                                     Callbacks
# ------------------------------------------------------------------------------


func _on_deploy_settings_menu_visibility_changed():
	if is_hidden():
		emit_signal('finished_editing', self)
	else:
		emit_signal('request_populate', self)
		emit_signal('request_fill', self)
