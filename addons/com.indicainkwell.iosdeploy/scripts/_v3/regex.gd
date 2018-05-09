# regex.gd
extends '../regex.gd'


# ------------------------------------------------------------------------------
#                                       Init
# ------------------------------------------------------------------------------


func _initialize(): pass


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func get_pattern():
	return _backing.get_pattern()


func get_group_count():
	# + 1 because v2 considers the whole pattern a group
	return _backing.get_group_count() + 1


func search(text, offset=0, end=-1):
	var result = []

	var matched = _backing.search(text, offset, end)
	if matched == null:
		return result

	result.resize(get_group_count())
	for i in get_group_count():
		result[i] = matched.get_string(i)
	
	return result
