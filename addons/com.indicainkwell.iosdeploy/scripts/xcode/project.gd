# xcode/project.gd
#
# Loosely reflects a project.xcodeproj by managing bundle id, name, team,
# provision, info plist, and builds and deploys to devices.
tool
extends Reference


# ------------------------------------------------------------------------------
#                                      Signals
# ------------------------------------------------------------------------------


signal built(this, result, errors)
signal deployed(this, result, errors, device_id)


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const stc = preload('../static.gd')
const PBXPROJ_UUIDS = {
	FILE_REF = 'DEADDEADDEADDEADDEADDEAD',
	BUILD_FILE = 'BEEFBEEFBEEFBEEFBEEFBEEF',
}


# ------------------------------------------------------------------------------
#                                     Subtypes
# ------------------------------------------------------------------------------


var Shell = stc.get_gdscript('shell.gd')
var iOSDeploy = stc.get_gdscript('xcode/ios_deploy.gd')
var PList = stc.get_gdscript('xcode/plist.gd')
var PBX = stc.get_gdscript('xcode/pbx.gd')
var Team = stc.get_gdscript('xcode/team.gd')
var Provision = stc.get_gdscript('xcode/provision.gd')
var Device = stc.get_gdscript('xcode/device.gd')
var ErrorCapturer = stc.get_gdscript('xcode/error_capturer.gd')
var Capabilities = stc.get_gdscript('xcode/capabilities.gd')


class _Lib:

	const FileTypeDomains = [
		"archive.ar", "compiled.mach-o.dylib", "wrapper.framework"
	]
	const FileExts = [
		"a", "dylib", "framework"
	]
	enum Type {
		ARCHIVE=0, DYLIB, FRAMEWORK
	}

	# The global path to this lib file
	var _filepath
	# The type of this lib, @see _Lib.Type
	var _type

	func _init(filepath, type):
		_filepath = filepath
		_type = type
	
	func get_filepath():
		return _filepath

	func get_file_type_domain():
		return FileTypeDomains[_type]


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

var _libs = []

var _config

var _needs_building = true
var _iosdeploy = iOSDeploy.new()
var _runningdeploys = 0
var _devices = []

var _path

var _shell = Shell.new()
var _xcodebuild = _shell.make_command('xcodebuild')

var _log = stc.get_logger().make_module_logger(stc.PLUGIN_DOMAIN + '.xcode-project')
var _error_capturer = ErrorCapturer.new()


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _init():
	_iosdeploy.connect('deployed', self, '_on_deployed')

	# 1. Error Category (system)
	# 2. Error Message
	# -------------------------------->1           2
	_error_capturer.set_regex_pattern('(.*) Error: (.*)')
	_error_capturer.set_error_captures_map({
		category = 1,
		message = 2
	})


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func open(xcode_project_path):
	_path = xcode_project_path
	if not Directory.new().dir_exists(_path):
		return FAILED
	return OK


func mark_needs_building():
	_needs_building = true


func needs_building():
	return _needs_building


# ------------------------------------------------------------------------------
#                                       Libs
# ------------------------------------------------------------------------------


func add_lib(filepath):
	"""
	Add lib at filepath. Lib file must end in _Lib.FileExts. It must also
	have ios in its file name.
	@filepath String
	    Path to lib file to add.
	@return Error
	    OK when successfully added lib
	    ERR_FILE_BAD_PATH when failed
	"""
	var file = filepath.get_file()
	var ext = (file.extension() if stc.get_version().is2() else
		   file.get_extension())
	var ext_idx = _Lib.FileExts.find(ext)
	if file.find('ios') > -1 and ext_idx > -1:
		if Directory.new().file_exists(filepath):
			# ext_idx should map to _Lib.Type
			var lib = _Lib.new(filepath, ext_idx)
			_libs.append(lib)
			return OK

	return ERR_FILE_BAD_PATH


# ------------------------------------------------------------------------------
#                                    Config File
# ------------------------------------------------------------------------------


func set_config(cfg):
	"""
	Set the config to use for future reading and writing.
	"""
	_config = cfg

	# TODO: get rid of null not being a default value by creating a subclass
	# of Config to handle our general config use case
	automanaged = _config.get_value('xcode/project', 'automanaged', automanaged)
	bundle_id = _config.get_value('xcode/project', 'bundle_id', bundle_id)
	custom_info = _config.get_value('xcode/project', 'custom_info', custom_info)
	debug = _config.get_value('xcode/project', 'debug', debug)
	name = _config.get_value('xcode/project', 'name', name)

	provision = Provision.new().FromDict(
		_config.get_value('xcode/project', 'provision', provision)
	)
	team = Team.new().FromDict(_config.get_value('xcode/project', 'team', team))

	var saved_device_dicts = _config.get_value('xcode/project', 'devices', [])
	if saved_device_dicts.size() != 0:
		_devices.clear()
		for dev in saved_device_dicts:
			_devices.append(Device.new().FromDict(dev))


# -- Updating (config)


func update_config():
	"""
	Update config with self's properties.
	"""
	_config.set_value('xcode/project', 'automanaged', automanaged)
	_config.set_value('xcode/project', 'bundle_id', bundle_id)
	_config.set_value('xcode/project', 'name', name)
	_config.set_value('xcode/project', 'provision', Provision.new().ToDict(provision))
	_config.set_value('xcode/project', 'team', Team.new().ToDict(team))

	var savable_devices_fmt = []
	for device in _devices:
		savable_devices_fmt.append(Device.new().ToDict(device))
	_config.set_value('xcode/project', 'devices', savable_devices_fmt)

	# TODO: abstract this save out, self should not know about the path to
	# config.cfg
	if _config.save(stc.get_data_path('config.cfg')) != OK:
		stc.get_logger().info('unable to save config')




# ------------------------------------------------------------------------------
#                                      Devices
# ------------------------------------------------------------------------------


func get_devices():
	return _devices


func set_devices(devices):
	"""
	Add devices to associate with project.
	
	When project is built with xcode
	and automanaged is on devices will automatically be registered to
	provisioning profile if needed.
	
	These devices will also be used to deploy to.
	"""
	_devices = devices


# ------------------------------------------------------------------------------
#                                       Paths
# ------------------------------------------------------------------------------


func get_path():
	return _path


func get_xcodeproj_path():
	return get_path().plus_file('godot_ios.xcodeproj')


func get_app_path():
	var build = 'Debug' if debug else 'Release'
	return get_path().plus_file('build/%s-iphoneos/%s.app'%[build,name])


func get_pbx_path():
	return get_xcodeproj_path().plus_file('project.pbxproj')


func get_info_plist_path():
	return get_path().plus_file('godot_ios/godot_ios-Info.plist')


# ------------------------------------------------------------------------------
#                                     Updating
# ------------------------------------------------------------------------------


func update():
	update_pbx()
	update_info_plist()
	update_config()


func update_pbx():
	# Steps:
	# 1. Add project file ref as PBXFileReference
	#   - isa = PBXFileReference
	#   - lastKnownFileType = folder
	#   - name = godot project folder name
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
	# 5. Erase PROVISIONING_PROFILE in buildSettings
	#   - isa = XCBuildConfiguration
	#   - buildSettings = dict of settings
	# 6. Set system capabilities in rootObject
	#   - isa = PBXProject
	#   - attributes/TargetAttributes/<TARGET_OBJID>/SystemCapabilities
	# 7. Process Lib Files
	#   1. Make lib file references
	#     - isa = PBXFileReference
	#     - lastKnownFileType = _Lib.FileTypeDomains
	#     - name = libname.ext
	#   2. Add lib file reference to Frameworks group
	#   3. Make lib build file
	#     - isa = PBXBuildFile
	#     - fileRef = lib file reference
	#   4. Add lib build file to PBXFrameworksBuildPhase.files
	#     - isa = PBXFrameworksBuildPhase
	#     - files = [PBXBuildFile]
	
	var pbx = PBX.new()
	if pbx.open(get_pbx_path()) != OK:
		_log.info('Unable to open pbxproj for updating at ' + get_pbx_path())
		return

	# add godot project file reference
	
	pbx.add_object(PBXPROJ_UUIDS.FILE_REF, 'PBXFileReference', {
		lastKnownFileType = 'folder',
		name = stc.get_project_dir_name(),
		path = stc.get_project_path(),
	})
	
	pbx.add_object(PBXPROJ_UUIDS.BUILD_FILE, 'PBXBuildFile', {
		fileRef = PBXPROJ_UUIDS.FILE_REF,
	})
	
	# pbx queries
	
	var root_pbxgroup_q = PBX.Query.new()
	root_pbxgroup_q.type = 'PBXGroup'
	root_pbxgroup_q.excludekeypath = 'name'
	
	var resource_build_phase_q = PBX.Query.new()
	resource_build_phase_q.type = 'PBXResourcesBuildPhase'

	var xc_build_configuration_q = PBX.Query.new()
	xc_build_configuration_q.type = 'XCBuildConfiguration'
	xc_build_configuration_q.keypath = 'buildSettings/PROVISIONING_PROFILE'

	var proj_target_attr_q = PBX.Query.new()
	proj_target_attr_q.type = 'PBXProject'
	proj_target_attr_q.keypath = 'attributes/TargetAttributes'

	var all_file_refs_q = PBX.Query.new()
	all_file_refs_q.type = 'PBXFileReference'

	var frameworks_group_q = PBX.Query.new()
	frameworks_group_q.type = 'PBXGroup'
	frameworks_group_q.keypath = 'name'
	frameworks_group_q.keypathvalue = 'Frameworks'

	var frameworks_build_phase_q = PBX.Query.new()
	frameworks_build_phase_q.type = 'PBXFrameworksBuildPhase'
	frameworks_build_phase_q.keypath = 'files'

	var res = pbx.find_objects([
		root_pbxgroup_q,          # res[0]
		resource_build_phase_q,   # res[1]
		xc_build_configuration_q, # res[2]
		proj_target_attr_q,       # res[3]
		all_file_refs_q,          # res[4]
		frameworks_group_q,       # res[5]
		frameworks_build_phase_q  # res[6]
	])

	# add godot project folder to xcode project
	var pbxgroup_children = res[0][0]['children']
	if not pbxgroup_children.has(PBXPROJ_UUIDS.FILE_REF):
		pbxgroup_children.append(PBXPROJ_UUIDS.FILE_REF)
	
	# add godot project folder to xcode copy resource build phase
	var buildphase_files = res[1][0]['files']
	if not buildphase_files.has(PBXPROJ_UUIDS.BUILD_FILE):
		buildphase_files.append(PBXPROJ_UUIDS.BUILD_FILE)
	
	# Erase the PROVISIONING_PROFILE in xcode editor buildSettings because
	# it causes automanage to fail with an error saying it expects to be
	# automatically signed but provisioning profile is still specified which
	# implies manual signing.
	for build_cfg in res[2]:
		build_cfg['buildSettings'].erase('PROVISIONING_PROFILE')
	
	# Remove SystemCapabilities requirements if team is a free account
	# Or Add Capabilities if team is in apple developer program
	#
	# SystemCapabilities is in main PBXProject object, under
	# attributes/TargetAttributes/<TARGET_OBJID>. There can be multiple
	# targets.
	#
	# TODO: add a way for user to enable or disable capabilities
	assert(team != null)
	for proj in res[3]:
		var target_attr = proj['attributes']['TargetAttributes']
		for target_id in target_attr:
			var target = target_attr[target_id]
			if team.is_free_account:
				target['SystemCapabilities'] = {}
			else:
				var cap = Capabilities.new()
				target['SystemCapabilities'] = cap.to_dict()
			_log.debug(target)
	
	# Process lib files

	var newly_added_libs = _libs.duplicate()
	# remove found and already processed libs from newly_added_libs
	for file_ref_obj in res[4]:
		if not file_ref_obj.has('lastKnownFileType'):
			continue
		var ft = file_ref_obj['lastKnownFileType']
		if not (ft in _Lib.FileTypeDomains):
			continue
		for lib in _libs:
			if file_ref_obj['name'] != lib.get_filepath().get_file():
				continue

			# file_ref_obj represents lib from here on
			# update path in case it has changed
			file_ref_obj['path'] = lib.get_filepath()

			newly_added_libs.erase(lib)
	
	# the left over libs in newly_added_libs are the actual new libs
	for new_lib in newly_added_libs:
		# create a pbxfileref object for each new lib
		var lib_file_ref_id = pbx.generate_unique_object_id()
		pbx.add_object(lib_file_ref_id, 'PBXFileReference', {
			name = new_lib.get_filepath().get_file(),
			path = new_lib.get_filepath(),
			lastKnownFileType = new_lib.get_file_type_domain()
		})

		# then add it to frameworks group if it exists
		if res[5].size() > 0:
			# use first frameworks group
			var frameworks_group = res[5][0]
			if not frameworks_group.has('children'):
				frameworks_group['children'] = []
			frameworks_group['children'].append(lib_file_ref_id)

		# then add pbxbuildfile object for lib
		var lib_build_file_id = pbx.generate_unique_object_id()
		pbx.add_object(lib_build_file_id, 'PBXBuildFile', {
			fileRef = lib_file_ref_id
		})

		# lastly add lib_build_file_id to PBXFrameworksBuildPhase.files
		for frameworks_build_phase in res[6]:
			if not frameworks_build_phase.has('files'):
				frameworks_build_phase['files'] = []
			frameworks_build_phase['files'].append(lib_build_file_id)


	pbx.save_plist(get_pbx_path())
	mark_needs_building()


func update_info_plist():
	
	var plist = PList.new()
	if plist.open(get_info_plist_path()) != OK:
		_log.info('Unable to open infoplist for updating at ' + get_info_plist_path())
		return
	
	plist.set_value("CFBundleDisplayName", name)
	plist.set_value("CFBundleIdentifier", bundle_id)
	plist.set_value("godot_path", stc.get_project_dir_name())
	
	if stc.get_version().is3():
		# TODO: plist should escape shell stuff
		plist.set_value('CFBundleExecutable', "\\\\\\${EXECUTABLE_NAME}")
	
	for key in custom_info:
		plist.set_value(key, custom_info[key])
	
	plist.save()
	mark_needs_building()


# ------------------------------------------------------------------------------
#                                     Building
# ------------------------------------------------------------------------------


func build():
	assert(team != null)
	assert(bundle_id != null)
	assert(_path != null)
	assert(name != null)

	_xcodebuild.run_async(_build_xcodebuild_args(), self, '_on_xcodebuild_finished')

	# Always needs building.
	# The game project needs to be copied and signed to app bundle by xcode.
	# needs building can be fully implemented when codesigner.gd is impl.
	# _needs_building = false


func built():
	return Directory.new().dir_exists(get_app_path())


func _on_xcodebuild_finished(command, result):
	var errors = _error_capturer.capture_from(result.output)
	emit_signal('built', self, result, errors)


func _build_xcodebuild_args():
	var args = ['build']
	
	args.append('-configuration')
	if debug:
		args.append('Debug')
	else:
		args.append('Release')
	
	args.append('-project')
	args.append(get_xcodeproj_path())
	
	if automanaged:
		args.append('-allowProvisioningUpdates')
		# TODO: xcodebuild needs a device_id specifier for registration
		# multiple destinations are allowed
		# How to be passed a device_id?
		# Only needed for when device has not been registered with
		# provision
		# -destination 'platform=iOS,id={device_id}'
		args.append('-allowProvisioningDeviceRegistration')
		args.append('CODE_SIGN_STYLE=Automatic')
	else:
		assert(provision != null)
		args.append('CODE_SIGN_STYLE=Manual')
		args.append('PROVISIONING_PROFILE_SPECIFIER='+provision.name)
	
	if stc.get_version().is3():
		args.append('ENABLE_BITCODE=NO')
		args.append('EXECUTABLE_NAME=godot_ios_executable_binary')
	
	args.append('PRODUCT_NAME='+name)
	args.append('PRODUCT_BUNDLE_IDENTIFIER='+bundle_id)
	args.append('DEVELOPMENT_TEAM='+team.id)

	_log.debug('XcodeBuild Args: '+str(args))
	
	return args


# ------------------------------------------------------------------------------
#                                     Deploying
# ------------------------------------------------------------------------------


func get_running_deploys_count():
	return _runningdeploys


func is_deploying():
	return _runningdeploys > 0


func deploy():
	"""
	Deploy project to devices associated with project.
	"""
	# TODO: shell.gd command should be able to kill running command.
	# TODO: add option to install or just launch
	_iosdeploy.bundle = get_app_path()
	_runningdeploys = get_devices().size()
	for device in get_devices():
		_iosdeploy.install_and_launch_on(device.id)


func _on_deployed(command, result, errors, device_id):
	_runningdeploys -= 1
	emit_signal('deployed', self, result, errors, device_id)
