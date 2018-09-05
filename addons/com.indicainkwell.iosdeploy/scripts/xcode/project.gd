# xcode/project.gd
#
# Loosely reflects a project.xcodeproj by managing bundle id, name, team,
# provision, info plist, and builds and deploys to devices.
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

	var res = pbx.find_objects([
		root_pbxgroup_q,          # res[0]
		resource_build_phase_q,   # res[1]
		xc_build_configuration_q, # res[2]
		proj_target_attr_q,       # res[3]
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
