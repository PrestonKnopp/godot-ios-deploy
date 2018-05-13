# controller.gd
tool
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
	get_menu().connect('request_populate', self, '_on_request_populate')
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


func _on_request_populate(menu):
	menu.populate_devices(_xcode.finder.find_devices())
	menu.populate_provisions(filter_provisions(_xcode.finder.find_provisions()))
	menu.populate_teams(_xcode.finder.find_teams())


func _on_request_fill(menu):
	if _xcode_project != null:
		menu.fill_devices_group(_xcode_project.devices)
		menu.fill_bundle_group(
			_xcode_project.name,
			_xcode_project.bundle_id
		)
		menu.fill_identity_group(
			_xcode_project.team,
			_xcode_project.automanaged,
			_xcode_project.provision
		)


func _on_finished_editing(menu):
	var bundle = menu.get_bundle_group()
	if _xcode_project == null: _xcode_project = _xcode.make_project()
	_xcode_project.bundle_id = bundle.id
	_xcode_project.name = bundle.display

	var identity = menu.get_identity_group()
	_xcode_project.team = identity.team
	_xcode_project.provision = identity.provision
	_xcode_project.automanaged = identity.automanaged

	var selected_devices = menu.get_active_devices()
	_xcode_project.set_devices(selected_devices)

	_xcode_project.update()




# -- OneClickButton


func _one_click_button_pressed():
	print('Showing menu')
	get_menu().show()
	return
