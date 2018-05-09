# pbx.gd
extends Reference


# ------------------------------------------------------------------------------
#                                    Sub Classes
# ------------------------------------------------------------------------------


class Query:
	var type
	var keypath
	var excludekeypath

	func _process(json, uuid, object):
		var valid = true
		if type != null:
			if not object.has('isa') or \
			   object['isa'] != type:
				valid = false

		var res
		var bad_res = "That's Number Wang!"

		if keypath != null:
			res = json.get_value('objects/'+uuid+'/'+keypath, bad_res)
			if res == bad_res:
				valid = false

		if excludekeypath:
			res = json.get_value('objects/'+uuid+'/'+excludekeypath, bad_res)
			if res != bad_res:
				valid = false

		return valid



# # -- Common PBX Object Structs

# class PBXObject:
# 	var uuid
# 	var _backing = {}
# 	func set_value(key, value):
# 		_backing[key] = value
# 	func get_value(key, default=null):
# 		if _backing.has(key):
# 			return _backing[key]
# 		return default
# 	func to_dict():
# 		return _backing

# class FileReference extends PBXObject:
# 	const type = 'PBXFileReference'
# 	var name
# 	var path
# 	var last_known_file_type


# class BuildFile extends PBXObject:
# 	const type = 'PBXBuildFile'
# 	var file_ref


# class ResourcesBuildPhase extends PBXObject:
# 	const type = 'PBXResourcesBuildPhase'
# 	var files


# class Group extends PBXObject:
# 	const type = 'PBXGroup'
# 	var name
# 	var children


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const stc = preload('../static.gd')


# ------------------------------------------------------------------------------
#                                     Subtypes
# ------------------------------------------------------------------------------


var Json = stc.get_gdscript('json.gd')
var Shell = stc.get_gdscript('shell.gd')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var _json = Json.new()
var _sh = Shell.new().make_command('/bin/bash')
var _log = stc.get_logger().make_module_logger(stc.PLUGIN_DOMAIN + '.pbx')


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


# func _init():
# 	pass


# ------------------------------------------------------------------------------
#                                     Data Repr
# ------------------------------------------------------------------------------


func get_dict():
	return _json.get_dict()


# ------------------------------------------------------------------------------
#                                      Objects
# ------------------------------------------------------------------------------


func get_object(uuid):
	return _json.get_value('objects/' + uuid)


func add_object(uuid, type, property_dict):
	property_dict['isa'] = type
	return _json.set_value('objects/' + uuid, property_dict)


func find_objects(queries):
	var objects = _json.get_value('objects')
	var qsize = queries.size()
	var qrange = range(0, qsize)
	var result = []
	result.resize(qsize)
	for i in qrange:
		result[i] = []
	
	for uuid in objects.keys():
		var object = objects[uuid]
		for i in qrange:
			var valid = queries[i]._process(object)
			if valid:
				result[i].append(object)
	
	return result



# ------------------------------------------------------------------------------
#                                     File Ops
# ------------------------------------------------------------------------------


func open(path):
	path = stc.globalize_path(path)

	if not File.new().file_exists(path):
		_log.error('file !exists at ' + path)
		return ERR_FILE_NOT_FOUND


	var pbxproj2json = stc.get_shell_script(stc.shell.pbxproj2json)
	var sh_res = _sh.run(pbxproj2json, path)

	_json.parse(sh_res.output[0])
	if _json.get_result().error != OK:
		_log.error('parsing json: ' + _json.get_result().error_string)
		return _json.get_result().error

	return OK


func save_json(path):
	var f = File.new()
	var err = f.open(path, File.WRITE_READ)
	if err != OK:
		_log.error('('+str(err)+') failed to open '+path+' for writing json data')
		return err

	f.store_string(_json.to_string())
	f.close()
	return OK


func save_plist(path):
	var tmp_json_path = '/tmp/%s.pbxproj.json' % stc.PLUGIN_DOMAIN
	var err = save_json(tmp_json_path)
	if err != OK:
		return err
	
	var json2plist = stc.get_shell_script(stc.shell.json2plist)
	var sh_res = _sh.run(json2plist, tmp_json_path, path)
	if sh_res.code != 0:
		_log.error('Failed to convert json2plist', sh_res.output)
	
	return OK
