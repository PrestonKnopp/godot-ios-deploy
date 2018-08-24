# error_capturer.gd
#
# A helper to capture errors from xcode project build and ios_deploy
extends Reference

const stc = preload('../static.gd')

var ErrorClass = stc.get_gdscript('xcode/error.gd')
var Regex = stc.get_gdscript('regex.gd')

var _error_regex = Regex.new()
var _capture_map

func set_regex_pattern(pattern):
	assert(_error_regex.compile(pattern) == OK)

func set_error_captures_map(dictmap):
	"""
	@dictmap Dictionary
	  fmt {errorClassProperty: captureIndex}
	  Example:
	    {category: 0, code: 1, message: 2}
	"""
	_capture_map = dictmap

func capture_from(input):
	"""
	@input [String]
	  The source in which to match errors.
	  If @input is an array, it will loop over each element and split
	  strings by newline.
	@return [ErrorClass]
	  Each ErrorClass is filled in using the map from
	  set_error_captures_map()
	"""
	var errors = []
	for string in input:
		for line in string.split('\n', false):
			var captures = _error_regex.search(line)
			if captures.size() == 0:
				# did not match
				continue
			var error = ErrorClass.new()
			for key in _capture_map:
				error.set(key, captures[_capture_map[key]])
			errors.append(error)
	return errors
