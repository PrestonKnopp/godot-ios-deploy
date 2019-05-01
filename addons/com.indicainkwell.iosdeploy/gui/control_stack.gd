# control_stack.gd
#
# A stack for presenting controls and remembering their order.
# A main control in the stack is referred to as a screen.
# Manages the children of `stack_root_path` as screens.
tool
extends Control


signal presenting(this)
signal screen_exiting(this, screen, to_screen)
signal screen_entering(this, from_screen, screen)


# ------------------------------------------------------------------------------
#                                       Types
# ------------------------------------------------------------------------------


class Screen:
	func _init(node_):
		"""
		Screen is a node under the stack_root_path that contains main ui
		elements.
		"""
		node = node_
	var index setget ,get_index
	func get_index(): return node.get_index()
	var node setget ,get_node
	func get_node(): return node


# ------------------------------------------------------------------------------
#                                      Exports
# ------------------------------------------------------------------------------


export(NodePath) var stack_root_path = @'.'


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var _screen_stack = []


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _ready():
	for screen_node in get_node(stack_root_path).get_children():
		screen_node.hide()


# ------------------------------------------------------------------------------
#                               Fetching Screen Info
# ------------------------------------------------------------------------------


var screen setget ,get_current_screen
func get_current_screen():
	return get_screen()

func get_screen(idx=-1):
	"""
	Get current screen by passing -1 or nothing.
	Get screen at idx by passing an index.
	@return Screen
	"""
	if idx == -1:
		return screen
	assert(has_screen_idx(idx))
	return Screen.new(get_node(stack_root_path).get_child(idx))


func get_screen_named(name):
	if has_screen_named(name):
		return Screen.new(get_node(stack_root_path).get_node(name))


func has_screen_idx(idx):
	return idx >= 0 and idx < get_screen_count()


func has_screen_named(name):
	return get_node(stack_root_path).has_node(name)


func get_screen_count():
	return get_node(stack_root_path).get_child_count()


# ------------------------------------------------------------------------------
#                                    Goto Screen
# ------------------------------------------------------------------------------


func goto_first():
	goto(0)


func goto_last():
	goto(get_screen_count() - 1)


func goto(idx):
	assert(has_screen_idx(idx))
	var from_screen = screen
	screen = get_screen(idx)
	if from_screen != null and from_screen.index != idx:
		emit_signal('screen_exiting', self, from_screen, screen)
		from_screen.node.hide()
	emit_signal('screen_entering', self, from_screen, screen)
	screen.node.show()


func goto_screen(screen_):
	goto(screen_.index)


func goto_named(name):
	assert(has_screen_named(name))
	goto_screen(get_screen_named(name))


func goto_next():
	goto(screen.index + 1)


func goto_prev():
	goto(screen.index - 1)


# ------------------------------------------------------------------------------
#                                Modify Screen Stack
# ------------------------------------------------------------------------------


func push(screen_idx):
	"""
	Push screen onto stack and set screen_idx's screen to screen.
	@return Screen
	  The screen_ passed in.
	"""
	if screen != null:
		_screen_stack.push_front(screen)
	goto(screen_idx)


func push_screen(screen_):
	push(screen_.index)


func push_named(name):
	assert(has_screen_named(name))
	push_screen(get_screen_named(name))


func pop():
	"""
	@return Screen?
	  Popped screen
	"""
	if _screen_stack.empty():
		return
	var screen_ = screen
	goto(_screen_stack.front().index)
	_screen_stack.pop_front()
	return screen_


# ------------------------------------------------------------------------------
#                                    Reset Stack
# ------------------------------------------------------------------------------


func reset():
	_screen_stack.clear()
	goto_first()


# ------------------------------------------------------------------------------
#                                     Callbacks
# ------------------------------------------------------------------------------


func _on_about_to_show():
	emit_signal('presenting', self)
	goto(0 if screen == null else screen.index)
