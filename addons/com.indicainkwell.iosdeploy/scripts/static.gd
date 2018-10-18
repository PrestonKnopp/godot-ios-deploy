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

const CONFIG_VERSION = 0

const LOGGER_SINGLETON_DOMAIN = PLUGIN_DOMAIN + '.logger.singleton'
const Logger = preload('logger.gd')

const CONFIG_SINGLETON_DOMAIN = PLUGIN_DOMAIN + '.config.singleton'
const Config = preload('plugin_config.gd')


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


static func isa(obj, type):
	return get_gdscript('isa.gd').test(obj, type)


static func get_version():
	# can't use get_gdscript here because
	# it's recursive
	var path
	if OS.has_method('get_engine_version'):
		path = GDSCRIPTS_2
	else:
		path = GDSCRIPTS_3
	
	return load(path.plus_file('version.gd')).new()


static func get_plugin_singleton(domain, script):
	# - What? This creates a singleton by setting metadata on an instance of
	# an already global and readily accessible godot object.
	# - Why project_settings.gd? Godot v2 Globals and Godot v3
	# ProjectSettings are global objects that allow metadata.
	var project_settings = get_gdscript('project_settings.gd')
	if not project_settings.has_metadata(domain):
		project_settings.set_metadata(domain, script.new())
	return project_settings.get_metadata(domain)


static func get_logger():
	# - Why? A single logger can have all subloggers associated. And their
	# output levels can be managed easier. Just now realizing this could
	# also be done with groups.
	# TODO: refactor logger into self contained script. Use groups api to
	# manage all loggers across project.
	return get_plugin_singleton(LOGGER_SINGLETON_DOMAIN, Logger)


static func get_config():
	return get_plugin_singleton(CONFIG_SINGLETON_DOMAIN, Config)


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
