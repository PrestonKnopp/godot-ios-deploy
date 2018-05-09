# regex.gd
extends Reference


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var _backing = RegEx.new()


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _init():
	_initialize()


# ------------------------------------------------------------------------------
#                                       Init
# ------------------------------------------------------------------------------


func _initialize():
	assert('Call stc.get_gdscript("regex.gd"), do not load directly'.empty())



# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func compile(pattern):
	return _backing.compile(pattern)


func get_pattern():
	"""
	Get the latest pattern.
	"""
	assert(false)


func get_group_count():
	"""
	Get the number of groups in the compiled pattern (not in a search result).
	"""
	assert(false)


func search(text, offset=0, end=-1):
	"""
	Search for pattern in given text. Returns an empty array when there is no match.
	Capture groups that did not match are returned as an empty string.
	"""
	assert(false)


func clear():
	_backing.clear()


func is_valid():
	return _backing.is_valid()
