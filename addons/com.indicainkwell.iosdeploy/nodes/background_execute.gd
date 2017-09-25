# background_execute.gd
tool
extends Node

signal executed(command, args, output)

var _thread

func is_executing():
	return _thread and _thread.is_active()

func execute(cmd, args):
	if not _thread:
		_thread = Thread.new()
	if is_executing(): 
		_thread.wait_to_finish()

	_thread.start(self, '_threaded_exec', [cmd, args])

func _threaded_exec(data):
	var out = []
	var p = OS.execute(data[0], data[1], true, out)
	emit_signal('executed', data[0], data[1], out)

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		_thread.wait_to_finish()
