# device_finder.gd
extends 'Finder.gd'


# ------------------------------------------------------------------------------
#                                   Dependencies
# ------------------------------------------------------------------------------


var Device = stc.get_gdscript('xcode/device.gd')
var Deploy = stc.get_gdscript('xcode/deploy.gd')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var _deploy = Deploy.new()


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _init():
	_deploy.connect('task_finished', self, '_on_deploy_task_finished')


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func _instruments_find_devices():
	var listknowndevices = stc.get_shell_script(stc.shell.listknowndevices)
	var res = _sh.run(listknowndevices)
	if res.code != 0:
		return []

	var devices = []

	# for some reason multiline output is all in first element
	for line in res.get_stdout_lines():
		# skip sims until add support for x86 project gen
		if line.find('] (Simulator)') != -1:
			continue

		var device = Device.new()
		var end_name_idx = line.rfind('[')
		device.name = line.substr(0, end_name_idx).strip_edges()


		var end_id_idx = line.find(']', end_name_idx)

		# move passed '['
		end_name_idx += 1

		var id_length = end_id_idx - end_name_idx
		device.id = line.substr(end_name_idx, id_length)

		device.type = device.Type.Unknown
		if device.name.findn('macbook') != -1:
			device.type = device.Type.Mac
		elif device.name.findn('iphone') != -1:
			device.type = device.Type.iPhone
		elif device.name.findn('ipad') != -1:
			device.type = device.Type.iPad

		devices.append(device)
	
	_finished(devices)


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func begin_find():
	_deploy.start_task(
		_deploy.ToolStrategy.TASK_LIST_CONNECTED_DEVICES,
		_deploy.make_task_arguments())


# ------------------------------------------------------------------------------
#                                     Handlers
# ------------------------------------------------------------------------------


func _on_deploy_task_finished(task, args, message, error, result):
	if task != _deploy.ToolStrategy.TASK_LIST_CONNECTED_DEVICES:
		return

	if typeof(result) == TYPE_ARRAY:
		_finished(result)
	else:
		_finished([])

