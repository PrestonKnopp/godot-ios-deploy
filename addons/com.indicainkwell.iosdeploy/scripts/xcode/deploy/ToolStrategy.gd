# ToolStrategy.gd
#
# The abstract base class for implementing deploy tool strategies. Although
# intended to be abstract, an instance of this can be used as a NullObject.
extends Reference


# ------------------------------------------------------------------------------
#                                      Signals
# ------------------------------------------------------------------------------


signal task_started(task, message)
signal task_progressed(task, message, step_current, step_total)
signal task_finished(task, message, error, result)


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const stc = preload('../../static.gd')
const KEY_PATH = 'path'
const TASK_LAUNCH_APP = 'Launch App'
const TASK_LIST_CONNECTED_DEVICES = 'List Connected Devices'


# ------------------------------------------------------------------------------
#                                   Inner Classes
# ------------------------------------------------------------------------------


class _OptionalToolArguments:
	var environment = {}
	var arguments = []
	var developer_image_path = ''
	var developer_image_sig_path = ''

class ToolArguments:
	var device_id
	var app_bundle_path
	var app_bundle_id
	var optional = _OptionalToolArguments.new()


class _TaskResult:
	var error = FAILED
	var message = 'Task Failed for an unknown reason'
	var result = null


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var _log = stc.get_logger().make_module_logger(str(stc.PLUGIN_DOMAIN, '.', 'ToolStrategy'))
var _tool
# map {task : thread}
var _tool_task_thread_map = {}


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _init():
	pass


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func get_tool():
	return _tool


# ------------------------------------------------------------------------------
#                                  Override-ables
# ------------------------------------------------------------------------------


func get_config_section():
	""" @override
	Get the config section for this tool.
	@returns String
	"""
	return _tool.get_name()

func get_config_keys():
	""" @override
	Get the config section key for this tool.
	Be sure to call super and append to returned array when overriding. By
	default it supplies a 'path' key to handle when the path changes.
	@returns [String]
	"""
	return [KEY_PATH]

func handle_config_key_change(key, value):
	""" @override
	Handle key change by overriding this method. Examples are setting extra
	options.
	Be ready to handle null values.
	Be sure to call super and pass in key, value if you do not handle the
	key change.
	"""
	if key == KEY_PATH:
		if value == '' or value == null:
			set_tool_path(get_default_tool_path())
		else:
			set_tool_path(value)

func get_default_tool_path():
	""" @override
	Forward tool path.
	@returns String
	"""
	return _tool.get_default_path()

func set_tool_path(path):
	""" @override
	Forward set tool path.
	@path: String
	"""
	_tool.set_path(path)

func get_tool_path():
	""" @override
	Forward get tool path.
	@returns String
	"""
	return _tool.get_path()

func get_tool_name():
	""" @override
	Forward get tool name.
	@returns String
	"""
	return _tool.get_name()

func tool_available():
	""" @override
	Check if the environment for tool is available and ready to be used.
	@returns Bool
	"""
	return false


# ------------------------------------------------------------------------------
#                                  Strategy Tasks
# ------------------------------------------------------------------------------


func get_available_tasks():
	return [TASK_LAUNCH_APP, TASK_LIST_CONNECTED_DEVICES]


func start_task(task, arguments):
	if not task in get_available_tasks():
		_log.error("Error<%s>: Task<%s> not available"%[ERR_INVALID_PARAMETER, task])
		return
	var thread
	if _tool_task_thread_map.has(task):
		thread = _tool_task_thread_map[task]
		if thread.is_active():
			_log.info("Task<%s> already active"%[task])
			return
	else:
		thread = Thread.new()
		_tool_task_thread_map[task] = thread
	var data = {
		task = task,
		arguments = arguments,
		weak_thread = weakref(thread)
	}
	var err = thread.start(self, '_task_thread_func', data)
	if err != OK:
		_log.error("Error<%s>: Failed to start thread for task<%s>"%[err,task])
		return
	emit_signal("task_started", task, "Started task: "+task)


func _task_thread_func(data):
	var result = _TaskResult.new()
	_handle_task(data.task, data.arguments, result)
	# cleanup thread (from within thread func)
	var wthread = data.weak_thread.get_ref()
	if wthread != null and wthread.is_active():
		wthread.wait_to_finish()
	emit_signal("task_finished", result.message, result.error, result.result)


func _handle_task(task, arguments, result):
	""" @virtual
	Handle the task in the background. Call _task_emit_progress to notify
	listeners of progress.
	@task: String the task to handle
	@arguments: ToolArguments
	"""
	pass


func _task_emit_progress(task, message, step_current, step_total):
	call_deferred('emit_signal', 'task_progressed', task, message,
			step_current, step_total)

