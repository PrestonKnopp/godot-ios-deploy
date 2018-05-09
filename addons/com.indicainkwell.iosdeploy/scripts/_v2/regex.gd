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
	if _backing.find(text, offset, end) == -1:
		return []
	
	# if there is a match:
	# - v3's first capture element is the whole search text.
	# - v2's will only have up to the second capture or the whole search
	# text if there is < 2 capture groups
	#
	# Force assign whole search text to first element to be consistent with
	# v3
	var caps = _backing.get_captures()
	caps[0] = text
	return caps
