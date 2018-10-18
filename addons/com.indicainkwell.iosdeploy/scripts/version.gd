extends Object

# These functions aren't static because gdscript can't override static
# functions.

func get_dict():
	assert("Don't use version directly, call stc.get_gdscript('version.gd')".empty())

func get_major():
	return int(get_dict()['major'])

func get_minor():
	return int(get_dict()['minor'])

func get_patch():
	var d = get_dict()
	var patch = d['patch']
	return int(patch)

func get_status():
	return get_dict()['status']

func get_build():
	return get_dict()['build']

func get_string():
	return get_dict()['string']

func is2():
	return get_major() == 2

func is3():
	return get_major() == 3
