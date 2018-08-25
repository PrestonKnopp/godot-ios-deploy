# main_controller.gd
extends 'Controller.gd'


# ------------------------------------------------------------------------------
#                                      Signals
# ------------------------------------------------------------------------------


signal began_pipeline(this)
signal finished_pipeline(this)


# ------------------------------------------------------------------------------
#                                     Subtypes
# ------------------------------------------------------------------------------


var Xcode = stc.get_gdscript('xcode.gd')
var OnboardFlCtl = stc.get_gdscript('controllers/onboarding_flow_controller.gd')
var ProjSettings = stc.get_gdscript('project_settings.gd')


# ------------------------------------------------------------------------------
#                                      Scenes
# ------------------------------------------------------------------------------


var OneClickButtonScene = stc.get_scene('one_click_deploy_button.tscn')
var SettingsMenuScene = stc.get_scene('deploy_settings_menu.tscn')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var _log = stc.get_logger().make_module_logger(stc.PLUGIN_DOMAIN + '.main-controller')
var _xcode = Xcode.new()

var _config = ConfigFile.new()
var _settings = ProjSettings.new()
var _onboarding_flow_controller = OnboardFlCtl.new()

# TODO: refactor into controller
# var _settings_menu = SettingsMenuScene.instance()


# ------------------------------------------------------------------------------
#                                       Inits
# ------------------------------------------------------------------------------


func _init():
	view = OneClickButtonScene.instance()
	view.set_disabled(true)
	view.connect('pressed', self, '_on_view_pressed')
	view.connect('presenting_hover_menu', self, '_on_view_presenting_hover_menu')
	view.connect('settings_button_pressed', self, '_on_view_settings_button_pressed')
	view.connect('devices_list_edited', self, '_on_view_devices_list_edited')

	_init_config()
	_init_onboarding_flow_controller()
	_init_xcode()


func _init_config():
	# TODO: mv config loading and stuff to plugin
	if _config.load(stc.get_data_path('config.cfg')) != OK:
		_log.info('unable to load config')


func _init_onboarding_flow_controller():
	_onboarding_flow_controller.set_xcode(_xcode)
	add_child(_onboarding_flow_controller)


func _init_xcode():
	_xcode.template.connect('copy_install_failed', self, '_on_xcode_template_copy_install_failed')
	_xcode.connect('made_project', self, '_on_xcode_made_project')
	_xcode.make_project_async()


func _init_xcode_project():
	"""
	Only call after _xcode.make_project_async() successfully completes.
	"""
	_xcode.project.set_config(_config)
	_xcode.project.connect('built', self, '_on_xcode_project_built')
	_xcode.project.connect('deployed', self, '_on_device_deployed')
	_log.debug('Xcode Project App Path: ' + _xcode.project.get_app_path())


# ------------------------------------------------------------------------------
#                                  Node Overrides
# ------------------------------------------------------------------------------


func _enter_tree():
	get_plugin().add_control_to_container(
		get_plugin().CONTAINER_TOOLBAR,
		view
	)


func _exit_tree():
	view.queue_free()


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func get_menu():
	return _onboarding_flow_controller.view


func execute_deploy_pipeline():
	# Pipeline: Build Project -> Then Deploy to Devices
	emit_signal('began_pipeline', self)
	_update_xcode_project_custom_info(_xcode.project, _settings)
	view.update_build_progress(0.3, 'Building Xcode Project')
	_xcode.project.build()


func print_errors(errors, with_message=''):
	_log.error('>> %s' % with_message)
	for error in errors:
		_log.error('- Error(Code:%s, Category:%s, Message:%s)' %
				[error.code, error.category, error.message])
	_log.error('<<')



# -- Xcode


func check_xcode_make_project(oneclickbutton=null):
	if _xcode.template.exists():
		_log.debug('Xcode template installed after init. Attempting to make project...')
		view.disconnect('presenting_hover_menu', self, 'check_xcode_make_project')
		_xcode.make_project_async()
	else:
		view.get_node('hover_timer').stop()
		view.get_node('hover_panel').call_deferred('hide')

		# TODO: just use OS.alert()
		var alert = AcceptDialog.new()
		alert.set_text('Install Godot Export Templates to Deploy Project')
		alert.connect('confirmed', alert, 'queue_free')

		view.add_child(alert)
		alert.popup_centered()


# -- Xcode Project


func _update_xcode_project_custom_info(xcode_project, settings):
	var orientation
	if stc.get_version().is2():
		orientation = settings.get_setting('display/orientation')
	else:
		orientation = settings.get_setting('display/window/handheld/orientation')

	var mapped_ios_orientations = []
	if orientation in ['landscape', 'sensor_landscape', 'sensor']:
		mapped_ios_orientations.append('UIInterfaceOrientationLandscapeLeft')
	if orientation in ['reverse_landscape', 'sensor_landscape', 'sensor']:
		mapped_ios_orientations.append('UIInterfaceOrientationLandscapeRight')
	if orientation in ['portrait', 'sensor_portrait', 'sensor']:
		mapped_ios_orientations.append('UIInterfaceOrientationPortrait')
	if orientation in ['reverse_portrait', 'sensor_portrait', 'sensor']:
		mapped_ios_orientations.append('UIInterfaceOrientationPortraitUpsideDown')

	# TODO: there's no way to remove a past custom_info entry. a rogue entry
	# will be there until the generated template is trashed
	xcode_project.custom_info['UISupportedInterfaceOrientations'] = mapped_ios_orientations
	xcode_project.custom_info['UISupportedInterfaceOrientations~ipad'] = mapped_ios_orientations
	xcode_project.update_info_plist()


# -- Validation


func valid_team(team, provision):
	if team == null or provision == null:
		return false
	return provision.team_ids.has(team.id)


func valid_bundleid(bundle_id, provision):
	if bundle_id == null or provision == null or provision.bundle_id == null:
		return false
	return bundle_id.match(provision.bundle_id)


func valid_xcode_project():
	# Conditions for automanaged project to be valid
	if _xcode.project.provision == null and _xcode.project.automanaged and\
	   _xcode.project.team      != null:
		   return true
	# Conditions for non automanaged project to be valid
	return _xcode.project        != null and\
	   (_xcode.project.provision != null and\
	    _xcode.project.team      != null and\
	    valid_bundleid(_xcode.project.bundle_id, _xcode.project.provision) and\
	    valid_team(_xcode.project.team, _xcode.project.provision))


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
		# skip first provision in loop
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
	print('filling')
	menu.fill_devices_group(_xcode.project.get_devices())
	menu.fill_bundle_group(
		_xcode.project.name,
		_xcode.project.bundle_id
	)
	menu.fill_identity_group(
		_xcode.project.team,
		_xcode.project.automanaged,
		_xcode.project.provision
	)


func _on_edited_team(menu, new_team):
	if new_team == null:
		_xcode.project.team = null
		return

	# assert(new_team extends _xcode.Team)
	if _xcode.project.team != null and\
	   _xcode.project.team.id == new_team.id and\
	   _xcode.project.team.name == new_team.name:
		   return

	# make sure to set new team
	_xcode.project.team = new_team

	if _xcode.project.provision == null:
		return

	# Notify menu if provision is invalid due to new team

	if _xcode.project.provision.team_ids.has(new_team.id):
		menu.validate_provision()
		menu.validate_team()
	else:
		# provision is invalid as it does not support team
		menu.invalidate_provision()


func _on_edited_provision(menu, new_provision):
	if new_provision == null:
		_xcode.project.provision = null
		if not _xcode.project.automanaged:
			menu.invalidate_provision()
		return

	# assert(new_provision extends _xcode.Provision)
	if _xcode.project.provision != null and _xcode.project.provision.id == new_provision.id:
		return

	# make sure to set new provision
	_xcode.project.provision = new_provision

	# Notify menu if teams and bundleid are invalid due to new provision

	if _xcode.project.team != null:
		if new_provision.team_ids.has(_xcode.project.team.id):
			menu.validate_team()
		else:
			# team is invalid as it is not supported by provision
			menu.invalidate_team()

	# Check bundleid

	if _xcode.project.bundle_id == null or _xcode.project.bundle_id.empty():
		return

	if valid_bundleid(_xcode.project.bundle_id, new_provision):
		menu.validate_bundle_id()
	else:
		_xcode.project.bundle_id = new_provision.bundle_id
		# if bundle_id is a wildcard, invalidate so user
		# will edit
		if _xcode.project.bundle_id.find('*') > -1:
			menu.invalidate_bundle_id()
		_on_request_fill(menu)

	menu.validate_provision()


func _on_edited_bundle_id(menu, new_bundle_id):
	_xcode.project.bundle_id = new_bundle_id
	if _xcode.project.provision == null:
		return
	if valid_bundleid(new_bundle_id, _xcode.project.provision):
		menu.validate_bundle_id()
	else:
		menu.invalidate_bundle_id()


func _on_finished_editing(menu):
	var bundle = menu.get_bundle_group()
	_xcode.project.bundle_id = bundle.id
	_xcode.project.name = bundle.display

	var identity = menu.get_identity_group()
	_xcode.project.team = identity.team
	_xcode.project.provision = identity.provision
	_xcode.project.automanaged = identity.automanaged
	_xcode.project.set_devices(menu.get_active_devices())

	_xcode.project.update()


# -- OneClickButton (view)


func _on_view_pressed():
	_log.debug('OneClickButton: Pressed')
	if _xcode.is_project_ready():
		if not valid_xcode_project():
			get_menu().popup_centered()
		else:
			execute_deploy_pipeline()


func _on_view_presenting_hover_menu(oneclickbutton):
	_log.debug('OneClickButton: Presenting Hover Menu')
	if _xcode.is_project_ready():
		oneclickbutton.set_project_valid(valid_xcode_project())
		oneclickbutton.devices_list_populate(_xcode.finder.find_devices())
		oneclickbutton.devices_list_set_active(_xcode.project.get_devices())


func _on_view_settings_button_pressed(oneclickbutton):
	_log.debug('OneClickButton: Settings Button Pressed')
	if _xcode.is_project_ready():
		get_menu().popup_centered()


func _on_view_devices_list_edited(oneclickbutton):
	_log.debug('OneClickButton: Devices List Edited')
	if _xcode.is_project_ready():
		_xcode.project.set_devices(
			oneclickbutton.get_devices_list().get_active()
		)


# -- Xcode


func _on_xcode_template_copy_install_failed(template, error):
	if error == ERR_DOES_NOT_EXIST:
		# Hook up presenting hover menu so that we can make xcode
		# project at a later time when template has been installed by
		# user
		view.connect('presenting_hover_menu', self, 'check_xcode_make_project')



func _on_xcode_made_project(xcode, result, project):
	_log.debug('Xcode: Made Xcode Project')
	_init_xcode_project()
	view.set_disabled(false)


# -- Project


func _on_xcode_project_built(xcode_project, result, errors):

	if errors.size() > 0:
		print_errors(errors, 'Errors found while building Xcode Project')
		emit_signal('finished_pipeline', self)
		view.update_build_progress(1.0, 'Failed', true)
	elif xcode_project.get_devices().size() > 0:
		view.update_build_progress(0.5, 'Deploying %s/%s'%[1, xcode_project.get_devices().size()])
		xcode_project.deploy()
	else:
		emit_signal('finished_pipeline', self)
		view.update_build_progress(1.0, 'Done', true)


func _on_device_deployed(xcode_project, result, errors, device_id):

	if errors.size() > 0:
		print_errors(errors, 'iOSDeploy errors found while deploying to %s' % device_id)

	var runningdeploys = xcode_project.get_running_deploys_count()
	var devsiz = xcode_project.get_devices().size()
	var devnum = devsiz - runningdeploys
	view.update_build_progress(
		0.5 + float(devnum) / float(devsiz) * 0.5,
		'Deploying %s/%s' % [devnum, devsiz]
	)

	_log.debug('RUNNING DEPLOY %s' % runningdeploys)

	if not xcode_project.is_deploying():
		# this is the last device
		print('LAST DEPLOY')
		emit_signal('finished_pipeline', self)
		view.update_build_progress(1.0, 'Done', true)
