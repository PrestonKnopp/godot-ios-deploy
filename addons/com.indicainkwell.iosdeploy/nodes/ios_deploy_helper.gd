# iOSDeployHelper.gd
# interface to ios-deploy binary
tool
extends Node


signal detect_devices_result(devices)

signal deploy_result(arr_status)
signal deploy_remote_fs_result(arr_status)


enum CommandType {
	DETECT_DEVICE,
	REMOTE_FS_DEPLOY,
	INSTALL_DEPLOY
}


const _deploy = '/usr/local/bin/ios-deploy'


var _thread
var _queue = []


func detect_devices():
	var args = ['--detect', '--timeout', '1']
	var cmd = _Command.new(DETECT_DEVICE, 'detect_devices_result', args)
	_add_to_queue(cmd)

func remote_file_system_to(device, app_path, ip):
	var args = _get_deploy_args(device, app_path) + ['--args', '-rfs '+ip]
	var cmd = _Command.new(REMOTE_FS_DEPLOY, 'deploy_remote_fs_result', args)
	_add_to_queue(cmd)

func to(device, app_path):
	var args = _get_deploy_args(device, app_path, true)
	var cmd = _Command.new(INSTALL_DEPLOY, 'deploy_result', args)
	_add_to_queue(cmd)

# ------------------------------------------------------------------------------
#                              Private Types and Funcs
# ------------------------------------------------------------------------------


class _Command extends Object:
	var sig = null
	var type = null
	var args = null

	var retval = null
	var output = null
	func _init(t, s, a=null):
		type = t
		sig = s
		args = a

func _get_deploy_args(device, app_path, force_install=false):
	var args = ['--id', device.id, '--bundle', app_path, '--justlaunch']
	if not force_install:
		args.append('--noinstall')
	return args

func _add_to_queue(command):
	_queue.push_back(command)
	_start_thread()

func _start_thread():
	if not _thread:
		_thread = Thread.new()
	if _thread.is_active():
		_thread.wait_to_finish()
	_thread.start(self, '_threaded_deploy_helper')

# ------------------------------------------------------------------------------
#                                  Thread Helpers
# ------------------------------------------------------------------------------

func _threaded_deploy_helper(arg):
	print('threaded deploy helper arg: ', arg)
	while _queue.size() > 0:
		print('_queueing up')
		var command = _queue.front()
		_start_handling_command(command)
		_handle_device_command(command)
		_handle_deploy_commands(command)
		_finish_handling_command(command)
		_queue.pop_front()

# runs command. puts output in command.output
func _start_handling_command(command):
	var out = []
	OS.execute(_deploy, command.args, true, out)
	var _out = []
	for line in out:
		_out += Array(line.split('\n', false))
	command.output = _out

func _handle_deploy_commands(command):
	if command.type != REMOTE_FS_DEPLOY and command.type != INSTALL_DEPLOY: return
	print('deploy command output\n', command.output)
	command.retval = []

	# check for security warning
	var sec_warn = 'error: process launch failed: Security'
	# check if app has been launched
	var launch_warn = 'Application has not been launched'


	for line in command.output:
		print(line)
		if line.find(sec_warn) > -1:
			command.retval.push_back(ERR_UNAUTHORIZED)
		elif line.find(launch_warn) > -1:
			command.retval.push_back(FAILED)

	command.retval.push_back(command.output)


# handle command. finds device names in output sets result to command.retval

#[....] Waiting up to 1 seconds for iOS device to be connected
#[....] Found 3t2h4e03i5d9834098908340985890 (N71mAP, iPhone 6s, iphoneos, arm64) a.k.a. 'iPhone Name' connected through USB.
func _handle_device_command(command):
	if command.type != DETECT_DEVICE: return
	var devices = []
	for line in command.output:
		if line.find('Found') > -1:
			var parts = Array(line.split(' ', true))
			parts.pop_front() # [....]
			parts.pop_front() # Found

			var device = {}
			device.id = parts.front()
			parts.pop_front() # id

			# remove iphone types
			var part = parts.front()
			while not part.ends_with(')'):
				parts.pop_front()
				part = parts.front()
			parts.pop_front()

			parts.pop_front() # a.k.a

			# Get phone name
			var name_parts = []
			part = parts.front()
			while not part.ends_with("'"):
				if part.begins_with("'"):
					name_parts.append(part.substr(1, part.length() - 1))
				else:
					name_parts.append(part)
				parts.pop_front()
				part = parts.front()
			part = part.substr(0, part.length() - 1)
			name_parts.append(part)

			device.name = ''
			for p in name_parts:
				if device.name.empty():
					device.name = p
				else:
					device.name += " %s" % p

			devices.push_back(device)

	command.retval = devices

# calls command callback and passes command.retval
func _finish_handling_command(command):
	emit_signal(command.sig, command.retval)
	command.free()
