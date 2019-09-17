# main_controller.gd
extends 'Controller.gd'


# ------------------------------------------------------------------------------
#                                      Signals
# ------------------------------------------------------------------------------


signal began_pipeline(this)
signal finished_pipeline(this)


# ------------------------------------------------------------------------------
#                                   Dependencies
# ------------------------------------------------------------------------------


var Xcode = stc.get_gdscript('xcode.gd')
var OnboardFlCtl = stc.get_gdscript('controllers/onboarding_flow_controller.gd')
var SettingMenuCtl = stc.get_gdscript('controllers/settings_menu_controller.gd')
var ProjSettings = stc.get_gdscript('project_settings.gd')
var EditorDebugSettings = stc.get_gdscript('editor_debug_settings.gd')


# ------------------------------------------------------------------------------
#                                      Scenes
# ------------------------------------------------------------------------------


var OneClickButtonScene = stc.get_scene('one_click_deploy_button.tscn')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var _log = stc.get_logger().make_module_logger(stc.PLUGIN_DOMAIN + '.main-controller')
var _xcode = Xcode.new()

var _settings = ProjSettings.new()
var _editor_debug_settings = null # set after entered tree
var _onboarding_flow_controller = OnboardFlCtl.new()
var _settings_menu_controller = SettingMenuCtl.new()


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

	_init_onboarding_flow_controller()
	_init_settings_menu_controller()
	_init_xcode()


func _init_onboarding_flow_controller():
	_onboarding_flow_controller.set_xcode(_xcode)
	add_child(_onboarding_flow_controller)


func _init_settings_menu_controller():
	_settings_menu_controller.set_xcode(_xcode)
	add_child(_settings_menu_controller)


func _init_xcode():
	_init_xcode_finder()
	_xcode.template.connect('copy_install_failed', self, '_on_xcode_template_copy_install_failed')
	_xcode.connect('made_project', self, '_on_xcode_made_project')
	_xcode.make_project_async()


func _init_xcode_finder():
	_xcode.finder.connect('result', self, '_on_xcode_finder_result')


func _init_xcode_project():
	"""
	Only call after _xcode.make_project_async() successfully completes.
	"""
	_xcode.project.connect('built', self, '_on_xcode_project_built')
	_xcode.project.connect('deploy_started', self, '_on_xcode_project_deploy_started')
	_xcode.project.connect('deploy_progressed', self, '_on_xcode_project_deploy_progressed')
	_xcode.project.connect('deploy_finished', self, '_on_xcode_project_deploy_finished')
	_log.debug('Xcode Project App Path: ' + _xcode.project.get_app_path())


# ------------------------------------------------------------------------------
#                                  Node Overrides
# ------------------------------------------------------------------------------


func _enter_tree():
	get_plugin().add_control_to_container(
		get_plugin().CONTAINER_TOOLBAR,
		view
	)
	var es = get_plugin().get_editor_settings()
	_editor_debug_settings = EditorDebugSettings.new(es)


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


func log_errors(errors, with_message=''):
	var error_str = ''
	for error in errors:
		error_str += '- %s\n' % error.to_string()
	_log.error('%s\n%s' % [with_message, error_str])


func _get_ip_addr():
	var addrs = IP.get_local_addresses()
	for addr in addrs:
		# skip loopback and ipv6, editor doesn't seem to support ipv6
		if addr == '127.0.0.1' or\
		   addr.find('.') == -1:
			   continue
		return addr
	if stc.get_version().is2():
		return get_plugin().get_editor_settings().call('get', 'network/debug_host')
	else:
		return get_plugin().get_editor_settings().call('get_setting', 'network/debug/remote_host')


func _get_port():
	if stc.get_version().is2():
		return get_plugin().get_editor_settings().call('get', 'network/debug_port')
	else:
		return get_plugin().get_editor_settings().call('get_setting', 'network/debug/remote_port')


# -- Xcode


func check_xcode_make_project(oneclickbutton=null):
	if _xcode.template.get_existing_zip_path() != null:
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
		_xcode.finder.begin_find_devices()
		oneclickbutton.set_project_valid(valid_xcode_project())


func _on_view_settings_button_pressed(oneclickbutton):
	_log.debug('OneClickButton: Settings Button Pressed')
	if _xcode.is_project_ready():
		_settings_menu_controller.view.popup_centered()


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


# -- Finder


func _on_xcode_finder_result(finder, type, objects):
	if type == finder.Type.DEVICE:
		get_view().devices_list_populate(objects)
		get_view().devices_list_set_active(_xcode.project.get_devices())
	elif type == finder.Type.TEAM:
		pass
	elif type == finder.Type.PROVISION:
		pass


# -- Project


func _on_xcode_project_built(xcode_project, result, errors):

	_log.info('XCODEBUILD RESULT:\n' + str(result.output))

	if errors.size() > 0:
		log_errors(errors, 'Errors found while building Xcode Project')
		emit_signal('finished_pipeline', self)
		view.update_build_progress(1.0, 'Failed', true)
	elif xcode_project.get_devices().size() > 0:
		# can't find a better place to set these debug flags
		# remote_debug doesn't just work like this. Godot editor needs
		# to know about it but I don't think that functionality is
		# exposed.
		xcode_project.remote_debug = false #_editor_debug_settings.remote_debug
		if xcode_project.remote_debug:
			xcode_project.remote_addr = _get_ip_addr()
			xcode_project.remote_port = _get_port()
			_log.debug('Remote Debug Deploy: %s:%s' %
					[xcode_project.remote_addr,
					xcode_project.remote_port])
		xcode_project.debug_collisions = _editor_debug_settings.debug_collisions
		xcode_project.debug_navigation = _editor_debug_settings.debug_navigation
		xcode_project.deploy()
	else:
		emit_signal('finished_pipeline', self)
		view.update_build_progress(1.0, 'Done', true)


var  _device_deploy_progress_map = {}


func _on_xcode_project_deploy_started(project, device_count):
	_device_deploy_progress_map.clear()


func _on_xcode_project_deploy_progressed(project, device, message, step_current, step_total):
	_device_deploy_progress_map[device] = {
		n=device.name, msg=message, sc=step_current, st=step_total
	}
	_update_deploy_progress_status()


func _on_xcode_project_deploy_finished(project, device, message, error, result):
	var d
	if _device_deploy_progress_map.has(device):
		d = _device_deploy_progress_map[device]
	else:
		d = { sc=1, st=1 }
	
	d.n = device.name
	d.msg = message
	d.err = error
	d.res = result
	d.fin = not project.is_deploying()
	_device_deploy_progress_map[device] = d

	_update_deploy_progress_status()

	if d.fin:
		_log.debug('Last device has deployed.')
		emit_signal('finished_pipeline', self)


func _update_deploy_progress_status():
	var statuses = []
	var total_steps_completed = 0
	var total_steps = 0
	for prog in _device_deploy_progress_map.values():
		total_steps += prog.st
		total_steps_completed += prog.sc
		var status = '%s: %s %s/%s' % [prog.n, prog.msg, prog.sc, prog.st]
		if prog.has('err'):
			status += ' -- Error<%s>' % [prog.err]
		if prog.has('res'):
			status += ' -- Result<%s>' % [prog.res]
		statuses.append(status)
	# protect against division by 0
	if total_steps == 0 and total_steps_completed > 0:
		total_steps = total_steps_completed
	view.update_build_progress(
		float(total_steps_completed) / float(total_steps),
		stc.join_array(statuses, '\n'),
		_device_deploy_progress_map.has('fin') and _device_deploy_progress_map.fin
	)

