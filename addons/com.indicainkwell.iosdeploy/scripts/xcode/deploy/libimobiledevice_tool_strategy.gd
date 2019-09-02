# libimobiledevice_tool_strategy.gd
extends 'ToolStrategy.gd'


# ------------------------------------------------------------------------------
#                                   Dependencies
# ------------------------------------------------------------------------------


var Libimobiledevice = stc.get_gdscript('xcode/deploy/apis/libimobiledevice.gd')


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _init().():
	_tool = Libimobiledevice.new()


func _handle_task(task, arguments, result):
	if task == TASK_LAUNCH_APP:
		_task_emit_progress(task, 'Mounting developer image', 1, 3)

		var err
		err = _tool.mount_developer_image(
			arguments.device_id,
			arguments.optional.developer_image_path,
			arguments.options.developer_image_sig_path
		)

		if err == ERR_FILE_NOT_FOUND:
			result.error = err
			result.message = 'Developer image not found'
			return
		elif err == FAILED:
			result.message = 'Failed to mount developer image'
			return

		_task_emit_progress(task, 'Installing app', 2, 3)

		err = _tool.install_app(
			arguments.device_id,
			arguments.app_bundle_path
		)

		if err == ERR_FILE_NOT_FOUND:
			result.error = err
			result.message = 'App bundle path not found'
			return
		elif err == FAILED:
			result.message = 'Failed to install app'
			return

		_task_emit_progress(task, 'Launching app', 3, 3)

		err = _tool.launch_app(
			arguments.device_id,
			arguments.app_bundle_id,
			arguments.optional.arguments
		)

		if err == FAILED:
			result.message = 'Failed to launch app'
			return
	elif task == TASK_LIST_CONNECTED_DEVICES:
		_task_emit_progress(task, 'Finding connected device ids', 0, 1)
		var devices = []
		var ids = _tool.get_connected_device_ids()
		var size = ids.size()
		for i in size:
			_task_emit_progress(task, 'Getting device id info', i, size)
			var device = _tool.get_device_info(ids[i])
			if device != null:
				devices.append(device)
		result.result = devices
		result.error = OK
		result.message = ''

