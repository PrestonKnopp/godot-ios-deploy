# deploy_settings_menu.gd
#
# Use this class by pre filling the groups with
# the fill_* api.
#
# Give the ui suggestions for the user by using the
# populate_* api.
extends Panel


signal request_fill(this)
signal finished_editing(this)


onready var _ctnt = get_node('content_container/VBoxContainer')
onready var _bdlname = _ctnt.get_node('identifier_group/bundle_group/bundle_name')
onready var _bdldisp = _ctnt.get_node('identifier_group/bundle_group/bundle_display_name')
onready var _bdlid = _ctnt.get_node('identifier_group/bundle_group/bundle_id')
onready var _toptbutt = _ctnt.get_node('identifier_group/identity_group/team_name')
onready var _automngchk = _ctnt.get_node('identifier_group/identity_group/automanage_profile')
onready var _poptbutt = _ctnt.get_node('identifier_group/identity_group/profile_id')
onready var _devlist = _ctnt.get_node('devices_group/devices_list')


func _ready():
	pass


# ------------------------------------------------------------------------------
#                               Retrieving User Input
# ------------------------------------------------------------------------------


func get_bundle_group():
	return {
		name = _bdlname.get_text(),
		display = _bdldisp.get_text(),
		id = _bdlid.get_text(),
	}


func get_identity_group():
	return {
		team = _toptbutt.get_item_text(_toptbutt.get_selected()),
		automanaged = _automngchk.is_pressed(),
		profile = _poptbutt.get_item_text(_poptbutt.get_selected()),
	}


func get_active_devices():
	return _devlist.get_active()


# ------------------------------------------------------------------------------
#                                Filling Stored Data
# ------------------------------------------------------------------------------


func fill_bundle_group(name='', display_name='', id=''):
	_bdlname.set_text(name)
	_bdldisp.set_text(display_name)
	_bdlid.set_text(id)


func fill_identity_group(team='', automanaged=false, profile_id=''):
	_toptbutt.add_item(team)
	_toptbutt.select(0)
	_automngchk.set_pressed(true)
	_poptbutt.add_item(profile_id)
	_poptbutt.select(0)

func fill_devices_group(devices=[]):
	_devlist.populate(devices)


# ------------------------------------------------------------------------------
#                             Populating with new data
# ------------------------------------------------------------------------------


func populate_teams(teams=[]):
	for team in teams:
		_toptbutt.add_item(team)


func populate_profiles(profiles=[]):
	for profile in profiles:
		_poptbutt.add_item(profile)


func populate_devices(devices=[]):
	_devlist.populate(devices)


# ------------------------------------------------------------------------------
#                                     Callbacks
# ------------------------------------------------------------------------------


func _on_deploy_settings_menu_visibility_changed():
	if is_hidden():
		emit_signal('finished_editing', self)
	else:
		emit_signal('request_fill', self)
