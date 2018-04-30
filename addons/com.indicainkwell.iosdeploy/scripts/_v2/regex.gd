# regex.gd
extends '../regex.gd'


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var _pattern


# ------------------------------------------------------------------------------
#                                       Init
# ------------------------------------------------------------------------------


func _initialize(): pass



# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func compile(pattern):
	_pattern = pattern
	return .compile(pattern)


func get_pattern():
	return _pattern


func get_group_count():
	return _backing.get_capture_count()


func search(text, offset=0, end=-1):
	_backing.find(text, offset, end)
	return _backing.get_captures()
