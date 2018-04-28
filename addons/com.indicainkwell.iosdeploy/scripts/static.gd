# static.gd
extends Object

const PLUGIN_DOMAIN = 'com.indicainkwell.iosdeploy'

const PLUGIN_DATA_PATH = 'user://' + PLUGIN_DOMAIN

const ADDON_PREFIX = 'addons/' + PLUGIN_DOMAIN
const SHELL_SCRIPTS = ADDON_PREFIX + '/shell'

const GDSCRIPTS = ADDON_PREFIX + '/scripts'
const GDSCRIPTS_2 = GDSCRIPTS  + '/2'
const GDSCRIPTS_3 = GDSCRIPTS  + '/3'


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


static func globalize_path(path):
	var protocol = 'user://'
	if path.begins_with(protocol):
		return OS.get_data_dir().plus_file(path.right(protocol.length()))

	return get_gdscript('globalize_path.gd').globalize_path(path)


static func get_provisions_path():
	return OS.get_environment('HOME').plus_file('Library/MobileDevice/Provisioning Profiles')


static func get_ios_export_template_path():
	var home = OS.get_environment('HOME')
	var v = get_version()
	if v.is2():
		return home.plus_file('.godot/templates/GodotiOSXCode.zip')
	else:
		# TODO: figure out what to do for 3.0 export templates
		# NOTE: Different template name formats
		#       - 3.0-stable/
		#       - 3.0.2.stable/ <-- use this one
		var tname = '%s.%s.%s.%s' % [
			v.get_major(), 
			v.get_minor(), 
			v.get_patch(),
			v.get_status()
		]
		return home\
			.plus_file('Library/Application Support/Godot/templates')\
			.plus_file(tname)\
			.plus_file('iphone.zip')


static func get_data_template_path():
	# user://DOMAIN/templates/iphone.zip
	return get_data_templates_dir_path()\
		.plus_file(
			get_ios_export_template_path().get_file()
		)


static func get_data_templates_dir_path():
	# user://DOMAIN/templates
	return _get_data_path('templates')


static func _get_data_path(extended_by=''):
	var path = PLUGIN_DATA_PATH.plus_file(extended_by)
	
	var d = Directory.new()
	if not d.dir_exists(path):
		var err = d.make_dir_recursive(path)
		if err != OK:
			print('Error<%s> making path<%s>' % [err,path])
	return path


static func get_data_path():
	return _get_data_path()


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
