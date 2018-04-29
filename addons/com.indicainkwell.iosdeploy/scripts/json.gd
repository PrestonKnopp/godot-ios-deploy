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


func set_value(path, value):
	var np = NodePath(path)
	assert(np.get_name_count() > 0)
	var name = np.get_name(0)
	var current = _backing
	for i in range(np.get_name_count() - 1):
		name = np.get_name(i)
		if current.has(name):
			current = current[name]
		else:
			return ERR_DOES_NOT_EXIST
	current[name] = value
