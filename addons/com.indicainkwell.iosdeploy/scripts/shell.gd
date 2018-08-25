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

	# ------------------------------------------------------------------------------
	#                                       Async
	# ------------------------------------------------------------------------------

	var _thread_map = {}
	# thread.get_id() <- id is prepared when thread is fully spun up
	# happens to be to late for use case
	var _current_thread_id = 0
	var _thread_mutex = Mutex.new()

	func running(thread_id):
		"""
		Check for running threaded instance of this command.
		@param thread_id:string the id returned by run_async
		"""
		if not _thread_map.has(thread_id):
			return false

		var thread = _thread_map[thread_id].wthread.get_ref()
		return thread != null and thread.is_active()

	func wait(thread_id):
		"""
		Wait for running threaded instance of this command to finish.
		@param thread_id:string the id returned by run_async
		"""
		if running(thread_id):
			_thread_map[thread_id].wthread.get_ref().wait_to_finish()

	func run_async(args, func_obj, func_name, binds=[]):
		"""
		Run command with args on a background thread. Multiple calls
		spawn multiple threads. Pass func_obj, func_name, and binds for
		a callback when command is finished on bg thread.
		@param args:array array of string args
		@param func_obj:object object to call func_name on
		@param func_name:string the func to call on func_obj
		@param binds:array the optional arguments to pass to callback
		@return thread_id:int id of newly spun up thread that you can
		        use to query if it is running or wait for it to finish
		"""
		assert(typeof(binds) == TYPE_ARRAY)

		var thread = Thread.new()
		_current_thread_id += 1
		_thread_map[_current_thread_id] = {
			wthread = weakref(thread),
			cb = {
				obj = func_obj,
				name = func_name,
				binds = binds
			}
		}
		thread.start(self, '_run_thread', {cmd=name, args=args, thread=thread, thread_id=_current_thread_id})
		return _current_thread_id

	func _run_thread(data):
		"""
		The background thread func. It runs command, callsback, then
		waits till itself is finished and cleans itself up.
		"""
		var res = _shell.execute(data.cmd, data.args)
		emit_signal('finished', self, res)

		if data.thread.is_active():
			# manage the lifetime of multiple threads
			data.thread.wait_to_finish()

		
		_thread_mutex.lock()
		# Refactor objects that use Command.run_async to connect to the
		# finished signal. Run async should the be passed some unique
		# identifier to be passed to listeners. The listener can then
		# use that id to differentiate calls to run_async
		var cb = _thread_map[data.thread_id].cb
		cb.obj.callv(cb.name, [self, res] + cb.binds)

		_thread_map.erase(data.thread_id)
		_thread_mutex.unlock()


func execute(cmd, args=[]):
	var res = Result.new()
	res.pid = OS.execute(cmd, args, true, res.output)
	return res


func make_command(command):
	return Command.new(command, self)
