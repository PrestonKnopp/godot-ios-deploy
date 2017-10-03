tool
extends EditorPlugin


#const MAIN_SCENE_PATH = 'res://addons/com.indicainkwell.iosdeploy/main.tscn'
const MainScene = preload('main.tscn')

var main

# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _enter_tree():
	Globals.set('com.indicainkwell.iosdeploy', self)
	Globals.set_persisting('com.indicainkwell.iosdeploy', false)

	var errors = meets_software_requirements()
	if errors.size() > 0:
		print('Doesnt meet software requirements:')
		for error in errors:
			print('\t- ', error)
		return

	main = MainScene.instance()
	add_control_to_container(CONTAINER_TOOLBAR, main)


func _exit_tree():
	Globals.clear('com.indicainkwell.iosdeploy')
	main.queue_free()


func meets_software_requirements():
	var errors = []
	if OS.get_name() != 'OSX':
		errors.append('macOS is needed to build and deploy iOS projects')
		return errors

	if not ext_sw_exists('ios-deploy'):
		errors.append('ios-deploy is missing: install ios-deploy with homebrew -- brew install ios-deploy')

	if not ext_sw_exists('xcodebuild'):
		errors.append('xcodebuild is missing: install xcode command line tools')

	return errors


func ext_sw_exists(software):
	var out = []
	OS.execute('command', ['-v', software], true, out)
	return out.size() > 0


# ------------------------------------------------------------------------------
#                                      Logging
# ------------------------------------------------------------------------------


enum Log {
	INFO,
	ERR
}


const _LOG_MESSAGE = '[iOSDeploy]: '
func put(m1, m2='', m3='', m4=''):
	puta([str(m1), str(m2), str(m3), str(m4)])
func puta(message, separator=', ', logtype=Log.INFO):
	var cmess = _LOG_MESSAGE + str(message)
	var mtype = typeof(message)
	if mtype == TYPE_ARRAY or mtype == TYPE_STRING_ARRAY:
		cmess = _LOG_MESSAGE
		for i in range(message.size()):
			var part = message[i]
			cmess += str(part)
			if i < message.size() - 1:
				cmess += str(separator)

	if logtype == Log.ERR:
		printerr(cmess)
	else:
		print(cmess)
