extends '../version.gd'

func get_dict():
	var v = OS.get_engine_version()
	v['build'] = v['revision']
	v.erase('revision')
	return v
