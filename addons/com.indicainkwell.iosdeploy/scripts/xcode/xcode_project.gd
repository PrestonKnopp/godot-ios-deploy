# xcode_project.gd
#
# TODO: impl build
# DONE: move plist and pbx processing here
extends Reference


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const stc = preload('static.gd')
const PBXPROJ_UUIDS = {
	FILE_REF = 'DEADDEADDEADDEADDEADDEAD',
	BUILD_FILE = 'BEEFBEEFBEEFBEEFBEEFBEEF',
}


# ------------------------------------------------------------------------------
#                                     Subtypes
# ------------------------------------------------------------------------------


var PList = stc.get_gdscript('xcode/plist.gd')
var PBX = stc.get_gdscript('xcode/pbx.gd')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var bundle_id
var name

var team
var provision
var automanaged = false

var debug = true
var custom_info = {}

var _path
var _log = stc.get_logger()
var _log_mod = stc.PLUGIN_DOMAIN + '.xcode-project'


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _init():
	_log.add_module(_log_mod)


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func open(xcode_project_path):
	_path = xcode_project_path
	if not Directory.new().dir_exists(_path):
		return FAILED
	return OK


# ------------------------------------------------------------------------------
#                                       Paths
# ------------------------------------------------------------------------------


func get_path():
	return _path


func get_app_path():
	var build = 'Release'
	if debug: build = 'Debug'
	return get_path().plus_file('build/%s-iphoneos/%s.app'%[build,name])


func get_pbx_path():
	return get_path().plus_file('godot_ios.xcodeproj/project.pbxproj')


func get_info_plist_path():
	return get_path().plus_file('godot_ios/godot_ios-Info.plist')


# ------------------------------------------------------------------------------
#                                     Updating
# ------------------------------------------------------------------------------


func update():
	update_pbx()
	update_info_plist()


func update_pbx():
	# Steps:
	# 1. Add project file ref as PBXFileReference
	#   - isa = PBXFileReference
	#   - lastKnownFileType = folder
	#   - name = project name
	#   - path = "relative path"
	# 2. Add project as PBXBuildFile
	#   - isa = PBXBuildFile
	#   - fileRef = the above
	# 3. Add file ref to PBXGroup without name ie root group
	#   - isa = PBXGroup
	#   - children = array of ids
	# 4. Add build file to PBXResourcesBuildPhase
	#   - isa = PBXResourcesBuildPhase
	#   - files = array of ids

	var pbx = PBX.new()
	if pbx.open(get_pbx_path()) != OK:
		_log.info('Unable to open pbxproj for updating at ' + get_pbx_path(), _log_mod)
		return
	
	pbx.add_object(PBXPROJ_UUIDS.FILE_REF, 'PBXFileReference', {
		lastKnownFileType = 'folder',
		name = stc.get_project_dir_name(),
		path = stc.get_project_path(),
	})

	pbx.add_object(PBXPROJ_UUIDS.BUILD_FILE, 'PBXBuildFile', {
		fileRef = PBXPROJ_UUIDS.FILE_REF,
	})

	var root_pbxgroup_q = PBX.Query.new()
	root_pbxgroup_q.type = 'PBXGroup'
	root_pbxgroup_q.excludekeypath = 'name'
	
	var resource_build_phase_q = PBX.Query.new()
	resource_build_phase_q.type = 'PBXResourcesBuildPhase'

	var res = pbx.find_objects([root_pbxgroup_q, resource_build_phase_q])
	res[0]['children'].append(PBXPROJ_UUIDS.FILE_REF)
	res[1]['files'].append(PBXPROJ_UUIDS.BUILD_FILE)

	pbx.save_plist(pbxproj_path)



func update_info_plist():
	
	var plist = Plist.new()
	if plist.open(get_info_plist_path()) != OK:
		_log.info('Unable to open infoplist for updating at ' + get_info_plist_path(), _log_mod)
		return
	
	plist.set_value("CFBundleDisplayName", name)
	plist.set_value("CFBundleDisplayIdentifier", bundle_id)
	plist.set_value("godot_path", stc.get_project_dir_name())

	for key in custom_info:
		plist.set_value(key, custom_info[key])
	
	plist.save()


# ------------------------------------------------------------------------------
#                                     Building
# ------------------------------------------------------------------------------


func build(): pass
func built(): pass

