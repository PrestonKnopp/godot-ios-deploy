# controller.gd
extends Reference


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const stc = preload('static.gd')


# ------------------------------------------------------------------------------
#                                     Subtypes
# ------------------------------------------------------------------------------


var Xcode = stc.get_gdscript('xcode.gd')


# ------------------------------------------------------------------------------
#                                      Scenes
# ------------------------------------------------------------------------------


var OneClickButtonScene = stc.get_scene('one_click_deploy_button.tscn')
var SettingsMenuScene = stc.get_scene('deploy_settings_menu.tscn')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var _xcode = Xcode.new()
var _xcode_project

var _one_click_button = OneClickButtonScene.instance()
var _settings_menu = SettingsMenuScene.instance()



# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _init():
	_settings_menu.connect('request_fill', self, '_on_request_fill')
	_settings_menu.connect('finished_editing', self, '_on_finished_editing')


func free():
	get_view().queue_free()
	.free()


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func get_view():
	assert(_one_click_button != null)
	return _one_click_button


# ------------------------------------------------------------------------------
#                                     Callbacks
# ------------------------------------------------------------------------------


# -- SettingsMenu


func _on_request_fill(menu):
	var bundle = {
		name = '',
		disp = '',
		id = ''
	}
	if _xcode_project != null:
		bundle.name = _xcode_project.name
		bundle.disp = _xcode_project.name
		bundle.id = _xcode_project.bundle_id
	menu.fill_bundle_group(bundle.name, bundle.disp, bundle.id)

	var id = {
		team = '',
		automanaged = false,
		profile = ''
	}
	if _xcode_project != null:
		id.team = _xcode_project.team.name
		id.automanaged = _xcode_project.automanaged
		id.profile_id = _xcode_project.provision.name
	menu.fill_identity_group(id.team, id.automanaged, id.profile)

	var found_names = []

	var devices = _xcode.finder.find_devices()
	for device in devices:
		found_names.append(device.name)
	menu.fill_devices_group(found_names)
	found_names.clear()

	for provision in _xcode.finder.find_provisions():
		found_names.append(provision.app_id_name)
	menu.populate_profiles(found_names)
	found_names.clear()

	for team in _xcode.finder.find_teams():
		found_names.append(team.name)
	menu.populate_teams(found_names)





func _on_finished_editing(menu):
	pass


# -- OneClickButton
