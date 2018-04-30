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
	# Normalized search to behave like v2's find().
	
	# v2's groups that didn't match are returned as an
	# empty string. Here we init result with empty strings
	var result = []
	result.resize(get_group_count())
	for i in get_group_count():
		result[i] = ''
	
	var matched = _backing.search(text, offset, end)
	
	if matched == null:
		return result
	
	for i in get_group_count():
		result[i] = matched.get_string(i)
	
	return result
