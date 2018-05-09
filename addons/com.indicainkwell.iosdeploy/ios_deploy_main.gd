tool
extends EditorPlugin


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const stc = preload('scripts/static.gd')


# ------------------------------------------------------------------------------
#                                     Subtypes
# ------------------------------------------------------------------------------


var Controller = stc.get_gdscript('controller.gd')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var controller


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _enter_tree():
	if not meets_software_requirements():
		return
	controller = Controller.new()
	add_control_to_container(CONTAINER_TOOLBAR, controller.get_view())


func _exit_tree():
	controller = null


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

