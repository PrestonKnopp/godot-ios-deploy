# static.gd
extends Object

const PLUGIN_DOMAIN = 'com.indicainkwell.iosdeploy'
const LOGGER_DOMAIN = 'ios-deploy'

const PLUGIN_DATA_PATH = 'user://' + PLUGIN_DOMAIN

const ADDON_PREFIX = 'addons/' + PLUGIN_DOMAIN

const SCENES = ADDON_PREFIX + '/gui'
const SCENES_2 = SCENES + '/_v2'
const SCENES_3 = SCENES + '/_v3'

const SHELL_SCRIPTS = ADDON_PREFIX + '/shell'

const GDSCRIPTS = ADDON_PREFIX + '/scripts'
const GDSCRIPTS_2 = GDSCRIPTS  + '/_v2'
const GDSCRIPTS_3 = GDSCRIPTS  + '/_v3'


# Get rid of this and just use get_shell_script() with string input
const shell = {
	json2plist       = 'json2plist.sh',
	plist2json       = 'plist2json.sh',
	listknowndevices = 'listknowndevices.sh',
	listteamsjson    = 'listteamsjson.sh',
	cvtpbxproj2plist = 'cvtpbxproj2plist.sh',
	pbxproj2json     = 'pbxproj2json.sh',
	provision2json   = 'provision2json.sh',
	xcodebuild       = 'xcodebuild.sh',
}


static func get_version():
	# can't use get_gdscript here because
	# it's recursive
	var path
	if OS.has_method('get_engine_version'):
		path = GDSCRIPTS_2
	else:
		path = GDSCRIPTS_3

	return load(path.plus_file('version.gd')).new()


static func get_logger():
	var main_loop = get_gdscript('main_loop_getter.gd').new().get_main_loop()
	var nodes = main_loop.get_nodes_in_group(PLUGIN_DOMAIN)
	if nodes.size() != 1:
		print('ERROR GETTINGs LOGGER WITH #%s IN GROUP %s'%[nodes.size(),PLUGIN_DOMAIN])
		return null
	if nodes[0].get_name() != LOGGER_DOMAIN:
		print('ERROR GETTING LOGGER NODE %s IN GROUP %s, GOT %s INSTEAD'%[LOGGER_DOMAIN,PLUGIN_DOMAIN,nodes[0].get_name()])
		return null
	return nodes[0]



static func globalize_path(path):
	var gpath
	var protocol = 'user://'
	if path.begins_with(protocol):
		var get_data_dir = 'get_data_dir' if get_version().is2() else 'get_user_data_dir'
		gpath = OS.call(get_data_dir).plus_file(path.right(protocol.length()))
	else:
		gpath = get_gdscript('globalize_path.gd').globalize_path(path)
	
	# strip any ending /'s for paths consistency
	while gpath.ends_with('/'):
		gpath = gpath.left(gpath.length() - 1)
	return gpath


static func get_project_path():
	return globalize_path('res://')


static func get_project_dir_name():
	return get_project_path().get_file()


static func get_data_path(extended_by=null):
	if extended_by == null:
		return PLUGIN_DATA_PATH
	return PLUGIN_DATA_PATH.plus_file(extended_by)


static func get_scene(scene):
	# v2 and v3 scenes are incompatible
	if get_version().is2():
		return load(SCENES_2.plus_file(scene))
	else:
		return load(SCENES_3.plus_file(scene))


static func get_shell_script(shell_script):
	return SHELL_SCRIPTS.plus_file(shell_script)


static func get_gdscript(gdscript):

	var f = GDSCRIPTS.plus_file(gdscript)

	if get_version().is2():
		var v2f = GDSCRIPTS_2.plus_file(gdscript)
		if File.new().file_exists(v2f):
			f = v2f
	elif get_version().is3():
		var v3f = GDSCRIPTS_3.plus_file(gdscript)
		if File.new().file_exists(v3f):
			f = v3f

	return load(f)
