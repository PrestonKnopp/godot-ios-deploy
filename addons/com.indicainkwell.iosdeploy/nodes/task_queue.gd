# task_queue.gd
tool
extends Node


# NEEDS CLEANING
# Build like pipeline
# - each prev func pipes into next
# - depending on func pipes return value

signal finished_task(task, task_index, task_count)
signal finished(stack)


enum Route {
	NEXT,
	STOP,
	WAIT
}

class TaskRetVal:
	var route
	var vals = []
	func _init(r,v):
		route = r
		vals = v
	func setv(v):
		vals = v
		return self
	func setr(r):
		route = r
		return self

class Task:
	var next
	var function
	var vals = []

	var sigobj
	var signame
	var waiting = false
	var has_waited = false

	var callback
	var callback_vals

	func dothis(funcobj, funcname):
		function = {obj = funcobj, fun = funcname}
	func waitfor(sigobj, signame, callback_obj, callback_func):
		self.sigobj = sigobj
		self.signame = signame
		self.callback = {obj = callback_obj, fun = callback_func}
	func thendo(task):
		next = task


var _current_count = 0
var _current_index = 0
var head = null
var stack = []

func make_task_root():
	var new_task = Task.new()
	head = new_task
	return new_task

func make_task():
	return Task.new()

func make_task_retv(r=NEXT, v=[]):
	return TaskRetVal.new(r, v)

func _process(_):
	if head == null: finish(); return
	if head.waiting: return
	if head.has_waited:
		var retv = head.callback.obj.callv(head.callback.fun, head.callback_vals)
		print('Head has waited: ', head.callback.fun)
		print('\t ---- retv: ', retv.route, retv.vals)
		_handle_retv(retv)
		return
	
	print('\t ---- Processing: ', head.function.fun)
	
	if head.sigobj:
		head.sigobj.connect(head.signame, self, '_on_wait_signal_finished')

	var retv = head.function.obj.callv(head.function.fun, head.vals)
	assert(retv extends TaskRetVal)
	_handle_retv(retv)

func _handle_retv(retv):
	if retv.route == WAIT:
		head.waiting = true
	elif retv.route == NEXT:
		emit_signal('finished_task', head, _current_index, _current_count)
		_current_index += 1
		_pop()
		if head and retv.vals != null: 
			head.vals = retv.vals
	elif retv.route == STOP:
		finish()

func _count_tasks():
	var count = 0
	var cur = head
	while cur != null:
		count += 1
		cur = cur.next
	return count

func begin():
	_current_count = _count_tasks()
	_current_index = 0
	set_process(true)

func finish():
	set_process(false)
	emit_signal('finished', stack)

func _is_last():
	return head != null and head.next == null

func clear():
	head = null

func _pop():
	if _is_last(): return clear()
	head = head.next

class _NIL:
	var nil = null
func Nil():
	return _NIL.new()

func _on_wait_signal_finished(v1=Nil(), v2=Nil(), v3=Nil(), v4=Nil(), v5=Nil(), v6=Nil()):
	head.waiting = false
	head.has_waited = true
	
	print('Wait Signal Finished')
	
	var vs = [v1, v2, v3, v4, v5, v6]
	var bvs = []
	for v in vs:
		if typeof(v) == TYPE_OBJECT:
			if v extends _NIL: break
		bvs.append(v)
	
	head.callback_vals = bvs
