tool
extends EditorPlugin


const MAIN_SCENE_PATH = 'res://addons/com.indicainkwell.iosdeploy/main.tscn'
#const MainScene = preload('main.tscn')

var main

# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _enter_tree():
	Globals.set('com.indicainkwell.iosdeploy', self)
	Globals.set_persisting('com.indicainkwell.iosdeploy', false)
	
	var MainScene = ResourceLoader.load(MAIN_SCENE_PATH, '', true)
	main = MainScene.instance()
	add_control_to_container(CONTAINER_TOOLBAR, main)

func _exit_tree():
	Globals.clear('com.indicainkwell.iosdeploy')
	main.queue_free()


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
