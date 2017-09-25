# device_button.gd
tool
extends Popup

signal validated(device, is_valid)

signal none_detected()
signal one_detected()

# ask to popup
signal multiple_detected()
# after popup
signal new_selected()


var _validating = false
var _validating_device = null
var last_validate_result = null
var last_device_detect_result = []
var current_device = null setget ,get_current_device


onready var _list = get_node('device_list')
onready var _deploy = get_node('ios_deploy')
#onready var _timer = get_node('detect_timer')


# ------------------------------------------------------------------------------
#                                Setters and Getters
# ------------------------------------------------------------------------------


func validating(): return _validating
func get_current_device(): return current_device


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func detect():
	#_timer.start()
	_deploy.detect_devices()

func validate(device):
	_validating = true
	_validating_device = device
	_deploy.detect_devices()
	return self

func update_device_list():
	_list.clear()
	for dev in last_device_detect_result:
		_list.add_item(dev.name)

#func set_auto_detect_wait_time(time):
#	_timer.set_wait_time(time)
#
#func get_auto_detect_wait_time():
#	return _timer.get_wait_time()



# ------------------------------------------------------------------------------
#                                     Handlers
# ------------------------------------------------------------------------------


# -- This


func _on_confirmed():
	var items = _list.get_selected_items()
	if items.size() > 0:
		current_device = last_device_detect_result[items[0]]
		emit_signal('new_selected')

func _on_about_to_show():
	print('Devices about to show')
	update_device_list()


# -- Children


# --- Timer
func _on_detect_timer_timeout():
	_deploy.detect_devices()

# --- Device List
func _on_device_list_item_activated(idx):
	current_device = last_device_detect_result[idx]
	emit_signal('new_selected')
	hide()

# --- ios_deploy
func _on_ios_deploy_detect_devices_result(devices):
	last_device_detect_result = devices
	
	if not _list.is_hidden():
		update_device_list()
	
	if _validating:
		var is_valid = false
		for dev in devices:
			if dev.id == _validating_device.id:
				is_valid = true
				break
		emit_signal('validated', _validating_device, is_valid)
		last_validate_result = {device = _validating_device, valid = is_valid}
		_validating = false
		_validating_device = null
		return

	if devices.size() == 0:
		emit_signal('none_detected')
		current_device = null
	elif devices.size() == 1:
		emit_signal('one_detected')
		current_device = devices[0]
	elif devices.size() > 1:
		emit_signal('multiple_detected', devices[1])
