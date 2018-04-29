# shell.gd
extends Reference


class Result:
	var output = []
	var code = 0
	var pid = -1


class Command:
	var name
	var _shell

	signal finished(this, result)

	func _init(name, shell):
		self.name = name
		self._shell = shell

	func run(arg0=null, arg1=null, arg2=null, arg3=null, arg4=null, arg5=null, arg6=null):
		var _args = [arg0, arg1, arg2, arg3, arg4, arg5, arg6]
		var args = []
		for arg in _args:
			if arg == null: break
			var t = typeof(arg)
			if t == TYPE_ARRAY:
				args = args + arg
			elif t == TYPE_STRING:
				args.append(arg)
			else:
				args.append(str(arg))
		return _shell.execute(name, args)

	var _thread

	func running():
		return _thread and _thread.is_active()

	func wait():
		if running():
			_thread.wait_to_finish()

	func run_async(args, func_obj, func_name):
		if not _thread:
			_thread = Thread.new()
		wait()
		connect('finished', func_obj, func_name, CONNECT_ONESHOT)
		_thread.start(self, '_run_thread', {cmd=name, args=args})

	func _run_thread(data):
		var res = _shell.execute(data.cmd, data.args)
		emit_signal('finished', self, res)


func execute(cmd, args=[]):
	var res = Result.new()
	res.pid = OS.execute(cmd, args, true, res.output)
	return res


func make_command(command):
	return Command.new(command, self)
