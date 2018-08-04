# Data.gd
#
# Parent class of xcode data classes.
# Implements comparison of two data classes.
extends Reference

func equals(data, compare_keys=null):
	"""
	@data Data
	  The other Data class to compare to this.
	@compare_keys [String]
	  Specific keys to check. Will only check those keys for equality.
	"""
	if not data.has_method('to_dict'):
		return false

	var this = to_dict()
	var other = data.to_dict()

	return _compare_dicts(this, other, compare_keys)

func _compare_dicts(a, b, compare_keys=null):
	if compare_keys != null:
		for key in compare_keys:
			if a.has(key) and not b.has(key):
				return false
			if a[key] != b[key]:
				return false
		return true

	if a.keys().size() != b.keys().size():
		return false

	for key in a.keys():
		if not b.has(key):
			return false

		if typeof(a[key]) != typeof(b[key]):
			return false

		if typeof(a[key]) == TYPE_DICTIONARY:
			if _compare_dicts(a[key], b[key]):
				continue
			else:
				return false

		if a[key] != b[key]:
			return false
	
	return true

func to_dict():
	return {}

func from_dict(d):
	pass
