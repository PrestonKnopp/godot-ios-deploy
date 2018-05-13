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
	get_view().connect('pressed', self, '_one_click_button_pressed')
	get_menu().connect('request_fill', self, '_on_request_fill')
	get_menu().connect('finished_editing', self, '_on_finished_editing')


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func cleanup():
	get_view().queue_free()
	get_menu().queue_free()


func get_view():
	return _one_click_button


func get_menu():
	return _settings_menu


func filter_provisions(provisions):
	# Filter out
	# - expired
	# - duplicates -- Compare by app_id_name or name? I guess name.
	var valid_provisions = []
	var duplicates = {}
	var today = OS.get_unix_time()
	for provision in provisions:
		var expire = OS.get_unix_time_from_datetime(provision.expiration_date)
		if today > expire: continue
		if not duplicates.has(provision.name):
			duplicates[provision.name] = []
		duplicates[provision.name].append(provision)
		valid_provisions.append(provision)
	
	# for each duplicate:
	# - check creation_date
	# - keep latest
	# - erase oldest
	for provisions in duplicates.values():
		var latest = provisions[0]
		var latest_t = OS.get_unix_time_from_datetime(latest.creation_date)
		for i in range(1, provisions.size()):
			var next = provisions[i]
			var next_t = OS.get_unix_time_from_datetime(next.creation_date)
			if next_t > latest_t:
				valid_provisions.erase(latest)
				latest = next
				latest_t = next_t
			else:
				valid_provisions.erase(next)
	
	return valid_provisions


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

	for provision in filter_provisions(_xcode.finder.find_provisions()):
		found_names.append(provision.name)
	menu.populate_profiles(found_names)
	found_names.clear()

	for team in _xcode.finder.find_teams():
		found_names.append(team.name)
	menu.populate_teams(found_names)



func _on_finished_editing(menu):
	pass


# -- OneClickButton


func _one_click_button_pressed():
	pass
