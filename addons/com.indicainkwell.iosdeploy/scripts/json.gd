extends Reference


class ParseResult:
	var error
	var error_string = 'unsupported'
	var error_line = -1


# dictionary
var _backing = null
var _result = null


func parse(string):
	assert("Don't use json directly, call stc.get_gdscript('json.gd')".empty())

func to_string():
	assert(false)


func get_result():
	return _result


func get_dict():
	return _backing


func values():
	return _backing.values()


func keys():
	return _backing.keys()


func get_value(path, default=null):
	var np = NodePath(path)
	var current = _backing
	for i in range(np.get_name_count()):
		var name = np.get_name(i)
		if typeof(current) == TYPE_DICTIONARY and current.has(name):
			current = current[name]
		else:
			return default
	return current


func set_value(path, value, create_path=false):
	"""
	Set value at path, optionally creating path if it does not exist.
	"""
	var np = NodePath(path)
	assert(np.get_name_count() > 0)
	var last_name_idx = np.get_name_count() - 1
	var name = np.get_name(0)
	var current = _backing
	for i in range(last_name_idx):
		name = np.get_name(i)
		if not current.has(name):
			if not create_path:
				return ERR_DOES_NOT_EXIST
			current[name] = {}
		current = current[name]
	var last_name = np.get_name(last_name_idx)
	current[last_name] = value
	return OK
