# libimobiledevice.gd
#
# API for libimobiledevice suite of tools
#
# - get all connected device uuids:
#	`idevice_id --list`
#
# - get device information:
#	`ideviceinfo --udid <UUID>`
#	- parse keys: ProductType, ProductVersion, DeviceColor, DeviceName
#
# - mount developer image for running/debugging an app:
#	`ideviceimagemounter --udid <UUID> <IMAGE> <IMAGE_SIGNATURE>`
#	- You can check for developer images from
#		`xcode-select --print-path`/Platforms/iPhoneOS.platform/DeviceSupport/<ProductVersion>/DeveloperDiskImage.dmg{.signature}
#	- if there is no device support for <ProductVersion> tell user to update xcode
#
# - install an app bundle:
#	`ideviceinstaller --udid <UUID> --install <BUNDLE_PATH>`
#	`ideviceinstaller --udid <UUID> --upgrade <BUNDLE_PATH>`
#
# - launch an app on a device:
#	`idevicedebug --udid <UUID> [--env <KEY>=<VAL>...] run <BUNDLE_ID> <RUN_ARGS...>`
extends Reference


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const DOMAIN = 'libimobiledevice'
const DEFAULT_TOOL_DIR = '/usr/local/bin'
const UDID_ARG_SPEC = '--udid'
const DEVICE_INFO_KEY_MAP = {
	DeviceName = 'name',
	DeviceColor = 'color',
	ProductType = 'type', # or use DeviceClass?
	ProductVersion = 'version'
}
const stc = preload('../static.gd')


# ------------------------------------------------------------------------------
#                                   Dependencies
# ------------------------------------------------------------------------------


var Device = stc.get_gdscript('xcode/device.gd')
var Shell = stc.get_gdscript('shell.gd')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var _shell = Shell.new()
var _log = stc.get_logger().make_module_logger(stc.PLUGIN_DOMAIN + '.libimobiledevice')


# ------------------------------------------------------------------------------
#                                Setters and Getters
# ------------------------------------------------------------------------------


var tool_directory setget get_tool_directory
func get_tool_directory():
	if tool_directory == null:
		return tool_directory
	return DEFAULT_TOOL_DIR


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func get_default_tool_directory():
	return DEFAULT_TOOL_DIR

func get_tool_installer():
	return get_tool_directory().plus_file('ideviceinstaller')

func get_tool_image_mounter():
	return get_tool_directory().plus_file('ideviceimagemounter')

func get_tool_debug():
	return get_tool_directory().plus_file('idevicedebug')

func get_tool_info():
	return get_tool_directory().plus_file('ideviceinfo')

func get_tool_id():
	return get_tool_directory().plus_file('idevice_id')


func get_connected_device_ids():
	_log.verbose('Getting connected device ids')
	var result = _shell.execute(
		get_tool_id(), ['--list'],
		DOMAIN
	)
	if result.code != OK:
		_log.error('Error<%s>: Failed to get connected device ids: %s'%[result.code, result.output])
		return []
	var ids = _parse_device_ids_string(result.get_stdout_string())
	_log.debug(str('Connected device ids: ', ids))
	return ids

func _parse_device_ids_string(string):
	_log.verbose(str('Parsing device id output: ', string))
	var ids = []
	for line in string.split('\n', false):
		ids.append(line)
	return ids

func get_device_info(device_id):
	_log.verbose('Getting device<%s> info'%device_id)
	var result = _shell.execute(
		get_tool_info(), [UDID_ARG_SPEC, device_id],
		DOMAIN
	)
	if result.code != OK:
		_log.error('Error<%s>: Failed to get device<%s> info:\n%s'%[result.code, device_id result.output])
		return null
	var info = _parse_device_info_string(result.get_stdout_string())
	if info != null: info.id = device_id
	_log.debug(str('Parsed device: ', Device.new().ToDict(info)))
	return info

func _parse_device_info_string(string):
	var info = Device.new()
	for line in string.split('\n', false):
		for key in DEVICE_INFO_KEY_MAP:
			if not line.begins_with(key):
				continue
			var value = line.right(str(key, ': ').length())
			if key == 'ProductType':
				if value.begins_with('iPad'):
					info.type = Device.Type.iPad
				elif value.begins_with('iPhone'):
					info.type = Device.Type.iPhone
			else:
				info.set(DEVICE_INFO_KEY_MAP[key], value)
			break
	return info

func mount_developer_image(device_id, developer_img_path, developer_img_sig):
	_log.verbose('Mounting developer image<%s> to device<%s>'%[developer_img_path, device_id])
	if not File.new().file_exists(developer_img_path):
		_log.error('Error<%s>: Developer image path not found: %s'%[ERR_FILE_NOT_FOUND, developer_img_path])
		return ERR_FILE_NOT_FOUND
	if not File.new().file_exists(developer_img_sig):
		_log.error('Error<%s>: Developer image signature path not found: %s'%[ERR_FILE_NOT_FOUND, developer_img_sig])
		return ERR_FILE_NOT_FOUND
	var result = _shell.execute(
		get_tool_image_mounter(), [UDID_ARG_SPEC, device_id, developer_img_path, developer_img_sig],
		DOMAIN
	)
	if result.code != OK:
		_log.error('Error<%s>: Failed to mount developer image on device<%s>\n%s'%[result.code, device_id, result.output])
		return FAILED
	return OK

func install_app(device_id, app_bundle_path):
	_log.verbose('Installing bundle at path<%s> to device<%s>'%[app_bundle_path, device_id])
	if not File.new().file_exists(app_bundle_path):
		_log.error('Error<%s>: App bundle path<%s> not found'%[ERR_FILE_NOT_FOUND, app_bundle_path])
		return ERR_FILE_NOT_FOUND
	var result = _shell.execute(
		get_tool_installer(), [UDID_ARG_SPEC, device_id, '--install', app_bundle_path],
		DOMAIN
	)
	if result.code != OK:
		_log.error('Error<%s>: Failed to install app<%s> to
				device<%s>:\n%s'%[result.code, app_bundle_path, device_id, result.output])
		return FAILED
	return OK


func launch_app(device_id, app_bundle_id, arguments=[], environment={}):
	_log.verbose('Launching bundle<%s> on device<%s> with arguments<%s> and
			environment<%s>'%[app_bundle_id, device_id, arguments, environment])
	var result = _shell.execute(
		get_tool_debug(), _build_launch_app_args(device_id, app_bundle_id, arguments, environment)
		DOMAIN
	)
	if result.code != OK:
		_log.error('Error<%s>: Failed to launch bundle<%s> on device<%s> with arguments<%s> and
				environment<%s>: '%[app_bundle_id, device_id, arguments, environment, result.output])
		return FAILED
	return OK

func _build_launch_app_args(device_id, app_bundle_id, arguments, environment):
	var args = [UDID_ARG_SPEC, device_id]
	args.resize(arguments.size() + (environment.size() * 2))
	for key in environment:
		args.append('--env')
		args.append(str(key, '=', environment[key]))
	args.append(app_bundle_id)
	for run_arg in arguments:
		args.append(run_arg)
	return args
