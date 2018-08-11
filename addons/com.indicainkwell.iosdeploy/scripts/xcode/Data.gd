# Data.gd
#
# Parent class of xcode data classes.
# Implements comparison of two data classes.
tool
extends Reference


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


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
	"""
	Comparison impl for self.equals
	@return Bool
	  true when equal
	"""
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


# ------------------------------------------------------------------------------
#                                 Dict Conversions
# ------------------------------------------------------------------------------


func to_dict():
	""" @virtual
	Convert self into dict.
	@return Dictionary?
	"""
	return {}


func from_dict(d):
	""" @virtual
	Convert dict to self, in place.
	"""
	pass


# The following methods were static.
# However, it did not work because static functions cannot access the script
# object they are attached to. So, usage is as follows: DataObj.new().FromDict()

func FromDict(dict):
	"""
	Creates a data object from dict. When dict is null, returns null.
	@return Data?
	"""
	if dict == null: return null
	var this = get_script().new()
	this.from_dict(dict)
	return this


func ToDict(data):
	"""
	Creates a dict from a data object. When data is null, returns null.
	@return Dictionary?
	"""
	if data == null: return null
	return data.to_dict()
