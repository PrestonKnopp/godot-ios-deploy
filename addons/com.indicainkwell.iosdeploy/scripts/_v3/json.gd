extends '../json.gd'


func parse(string):
	var res = JSON.parse(string)
	_result = ParseResult.new()
	_result.error = res.error
	_result.error_string = res.error_string
	_result.error_line = res.error_line
	_backing = res.result
	if typeof(res.result) != TYPE_DICTIONARY:
		_result.error = ERR_CANT_CREATE
		_result.error_line = 0
		_result.error_string = 'Non object root json data is not supported for backwards compatibility'
		_backing = null
	return self


func to_string():
	return JSON.print(get_dict())
