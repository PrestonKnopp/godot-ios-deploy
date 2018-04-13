extends '../json.gd'


func parse(string):
	_result = ParseResult.new()
	_backing = Dictionary()
	_result.error = _backing.parse_json(string)
	return self


func to_string():
	return get_dict().to_json()
