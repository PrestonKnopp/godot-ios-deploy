# iOSDeployConfig.gd
tool
extends Node


const _CONFIG_SKELETON_PATH = 'res://addons/com.indicainkwell.iosdeploy/config/ios_deploy_skeleton.cfg'
const _CONFIG_USER_PATH = 'user://com.indicainkwell.iosdeploy/config/ios_deploy.cfg'


var _config = ConfigFile.new()
var _plugin


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _init():
	_plugin = Globals.get('com.indicainkwell.iosdeploy')

	var err
	var d = Directory.new()
	if not d.file_exists(_CONFIG_USER_PATH):
		print('Config does not exist')
		err = d.make_dir_recursive(_CONFIG_USER_PATH.basename())
		_handle_err(err)
		err = d.copy(_CONFIG_SKELETON_PATH, _CONFIG_USER_PATH)
		print('copying skeleton to user')
		if err != OK:
			_handle_err(err, 'Error Copying Default Config to User Config')
			return

	err = _config.load(_CONFIG_USER_PATH)
	_handle_err(err)


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func _handle_err(err, m=''):
	if err == OK:
		pass
	elif err == FAILED:
		_plugin.put('failed to open ', _CONFIG_USER_PATH, m)
	elif err == ERR_FILE_CANT_OPEN:
			_plugin.put('cant open ', _CONFIG_USER_PATH, m)
	elif err == ERR_PARSE_ERROR:
		_plugin.put('cant parse ios_deploy.cfg at _CONFIG_USER_PATH: ', _CONFIG_USER_PATH, m)
	else:
		_plugin.put('unknown config load response: ', err, m)

func get_config():
	return _config

func save_config():
	if not _config:
		_plugin.put('no config loaded')
		return

	var err = _config.save(_CONFIG_USER_PATH)
	if err == OK:
		_plugin.put('saved ', _CONFIG_USER_PATH)
	else:
		_plugin.put('problem saving ', _CONFIG_USER_PATH, ' with code: ', err)
