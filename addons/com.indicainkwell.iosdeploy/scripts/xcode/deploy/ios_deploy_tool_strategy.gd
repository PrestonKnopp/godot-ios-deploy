# ios_deploy_tool_strategy.gd
extends 'ToolStrategy.gd'


# ------------------------------------------------------------------------------
#                                   Dependencies
# ------------------------------------------------------------------------------


var iOSDeployTool = stc.get_gdscript('xcode/deploy/apis/ios_deploy.gd')


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _init().():
	_tool = iOSDeployTool.new()


func tool_available():
	return File.new().file_exists(get_tool_path())


func _handle_task(task, arguments, result):
	if task == TASK_LAUNCH_APP:
		_task_emit_progress(task, arguments, 'installing and launching app', 1, 1)
		var launch_result = _tool.install_and_launch_app(
			arguments.device_id,
			arguments.app_bundle_path,
			arguments.optional.arguments
		)
		result.error = launch_result.result.code
		result.message = stc.join_array(launch_result.errors)
	elif task == TASK_LIST_CONNECTED_DEVICES:
		_task_emit_progress(task, arguments, 'detecting devices', 1, 1)
		result.error = OK
		result.message = ''
		result.result = _tool.get_detected_devices()

