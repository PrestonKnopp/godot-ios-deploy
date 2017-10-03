# xcode_project.gd
tool
extends Node

signal built(output)

var scheme
var name
var path_ #setget set_project_path


onready var _exec = get_node('bgexecute')


# ------------------------------------------------------------------------------
#                                Setters and Getters
# ------------------------------------------------------------------------------


#func set_project_path(new_value):
#	name = path_.get_file().basename()
#	path_ = Globals.globalize_path(new_value)
#

# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------

func can_build():
	return scheme and name and path_

func build():
	print('building xcode project ', path_)

	var cmd = '/usr/bin/xcodebuild'
	var args = ['-project', path_, '-scheme', scheme]

	_exec.execute(cmd, args)

func get_release_app_path():
	# TODO: see if need to change BuildType-* for device type (ipad)
	return get_build_path().plus_file('Release-iphoneos').plus_file('%s.app' % name)

func get_debug_app_path():
	return get_build_path().plus_file('Debug-iphoneos').plus_file('%s.app' % name)

func has_app():
	return Directory.new().dir_exists(get_debug_app_path())

func get_build_path():

	# xcodebuild -showBuildSettings | grep TARGET_BUILD_DIR -- to get release
	# xcodebuild -showBuildSettings | grep BUILD_DIR | head -1 -- to get build dir

	# wrap with $() to avoid | being quoted by engine
	var cmd = '/bin/echo'
	var args = ['$(xcodebuild -project \'' + path_ + '\' -showBuildSettings | grep BUILD_DIR | head -1)']
	var out = []
	OS.execute(cmd, args, true, out)

	assert(out.size() == 1)

	var build_path = out[0].split(' = ')[1].strip_edges()
	return build_path


# ------------------------------------------------------------------------------
#                                     Handlers
# ------------------------------------------------------------------------------


func _on_bgexecute_executed(cmd, args, out):
	# Only build_project uses bgexecute
	emit_signal('built', out)
