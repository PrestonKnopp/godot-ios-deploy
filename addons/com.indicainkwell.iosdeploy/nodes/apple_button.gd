# apple_button.gd
#On Ready:
#	Check:
#		software requirements are met
#			if not, show guide window
#		for connected device
#On Apple Right Press:
#	Show deploy options:
#		justrun
#		installrun
#		remotefsrun
#On Apple Press:
#	Check:
#		xcode settings are set
#			if not, show settings
#		xcodeproj has been built
#			if not, build it in bg
#		device is chosen and valid
#			if not, show user and check every couple of seconds for
#			device
#	Then:
#		deploy to device with options
#			Check:
#				securityfail
#					show user
#
tool
extends Button


enum OptionsMenu {
	SHOW_SETTINGS = 0,
	SHOW_DEVICES = 1,
	BUILD_XCODEPROJ = 3,
	DEPLOY_OPTIONS = 5
}


onready var _xcode    = get_node('xcode')
onready var _tasks    = get_node('task_queue')
onready var _deploy   = get_node('deploy')
onready var _devices  = get_node('devices')
onready var _options  = get_node('_options_menu')
onready var _settings = get_node('settings_window')
onready var _progress = get_node('progress_bar')

# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _init():
	if not Globals.has('com.indicainkwell.iosdeploy'):
		# for running in editor
		Globals.set('com.indicainkwell.iosdeploy', preload('../ios_deploy_main.gd').new())


func _ready():
	setup_xcode()

	if _xcode.can_build() and not _xcode.has_app():
		_xcode.build()

	_devices.detect()

func _input_event(event):
	if event.type == InputEvent.MOUSE_BUTTON and \
	   event.button_index == BUTTON_RIGHT    and \
	   event.pressed:
		show_options_menu()

# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------

func show_options_menu():
	var s = get_size()
	var p = get_pos()
	_options.set_pos(p + s)
	_options.popup()

func is_config_valid():
	var conf = _settings.get_config()
	var path = conf.get_value('xcode', 'path', null)
	var name = conf.get_value('xcode', 'name', null)
	var scheme = conf.get_value('xcode', 'scheme', null)
	return path and name and scheme

func setup_xcode():
	var conf = _settings.get_config()
	var path = conf.get_value('xcode', 'path', null)
	var name = conf.get_value('xcode', 'name', null)
	var scheme = conf.get_value('xcode', 'scheme', null)
	_xcode.path_ = path
	_xcode.name = name
	_xcode.scheme = scheme


# ------------------------------------------------------------------------------
#                                 Pipeline / Queues
# ------------------------------------------------------------------------------

func make_deploy_queue():
	var next = _tasks.make_task()
	var cur = _tasks.make_task_root()

	cur.dothis(self, '_xcode_settings_set')
	cur.thendo(next)

	next.dothis(self, '_xcode_has_been_built')
	next.waitfor(_xcode, 'built', self, '_task_xcode_built_callback')

	cur = next
	next = _tasks.make_task()
	cur.thendo(next)

	next.dothis(self, '_device_is_valid')
	next.waitfor(_devices, 'validated', self, '_task_device_validated_callback')

	cur = next
	next = _tasks.make_task()
	cur.thendo(next)

	next.dothis(self, '_deploy_to_device')
	next.waitfor(_deploy, '_finished', self, '_task_deploy_finish_callback')

func _task_deploy_finish_callback(successful, errors):
	return _tasks.make_task_retv()

func _task_device_validated_callback(device, is_valid):
	var retv = _tasks.make_task_retv()
	if is_valid: return retv
	_devices.detect()
	_devices.popup_centered_ratio()
	return retv.setr(_tasks.Route.STOP)

func _task_xcode_built_callback(output):
	print('Xcode task built', output)
	return _tasks.make_task_retv()

func _xcode_settings_set():
	var retv = _tasks.make_task_retv()
	setup_xcode()
	if not _xcode.can_build():
		_settings.popup_centered_ratio()
		return retv.setr(_tasks.Route.STOP)
	return retv

func _xcode_has_been_built():
	var retv = _tasks.make_task_retv()
	if _xcode.has_app():
		return retv.setr(_tasks.Route.NEXT)

	_xcode.build()
	return retv.setr(_tasks.Route.WAIT)

func _device_is_valid():
	print('checking dev validity')
	_devices.validate(_devices.get_current_device())
	return _tasks.make_task_retv().setr(_tasks.Route.WAIT)

func _deploy_to_device():
	_deploy.app(_xcode.get_debug_app_path(), _devices.get_current_device())
	return _tasks.make_task_retv().setr(_tasks.Route.WAIT)

# ------------------------------------------------------------------------------
#                                     Handlers
# ------------------------------------------------------------------------------


# -- this
func _on_pressed():
	print('Apple Button Pressed')

	_progress.set_value(0)
	_progress.show()
	make_deploy_queue()
	_tasks.begin()
	set_disabled(true)

# -- xcode
func _on_xcode_project_built(output):
	print('xcode built', output)


# -- devices
func _on_devices_multiple_detected():
	# let user choose
	_devices.popup_centered_ratio()

func _on_devices_new_selected():
	pass

func _on_devices_none_detected():
	pass

func _on_devices_one_detected():
	pass


# -- deploy
func _on_deploy_failure(reasons):
	print('deploy failed: ', reasons)
	for reason in reasons:
		var a = get_node('alert')
		if reason == ERR_UNAUTHORIZED:
			a.set_text('You must verify your app or developer account on your iOS device by going to\nSettings > General > Device Management > Your account and tap verify.')
			a.popup_centered()
		elif reason == FAILED:
			a.set_text('Deploy failed for an undocumented/unknown reason')
			a.popup_centered()

func _on_deploy_success():
	print('successfull deploy')

# -- task_queue
func _on_task_queue_finished(stack):
	print('Task Queueu Finished')
	_progress.hide()
	set_disabled(false)

func _on_task_queue_finished_task(task, task_index, task_count):
	_progress.set_value(float(task_index) / float(task_count))
	if task.next != null:
		_progress.set_tooltip('processing ' + task.next.function.fun)

# -- options_menu
func _on_options_menu_item_pressed( ID ):
	if ID == SHOW_SETTINGS:
		_settings.popup_centered_ratio()
	elif ID == SHOW_DEVICES:
		_devices.detect()
		_devices.popup_centered_ratio()
	elif ID == BUILD_XCODEPROJ:
		setup_xcode()
		if _xcode.can_build():
			_xcode.build()
		else:
			_settings.popup_centered_ratio()
	elif ID == DEPLOY_OPTIONS:
		_deploy.popup()
		_deploy.set_pos(_options.get_pos())
	else:
		print('Unknown option selected')
