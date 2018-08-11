# xcode.gd
extends Reference


# ------------------------------------------------------------------------------
#                                      Signals
# ------------------------------------------------------------------------------


signal made_project(this, result, project)


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const stc = preload('static.gd')


# ------------------------------------------------------------------------------
#                                     Subtypes
# ------------------------------------------------------------------------------


var PList = stc.get_gdscript('xcode/plist.gd')
var PBX = stc.get_gdscript('xcode/pbx.gd')
var Project = stc.get_gdscript('xcode/xcode_project.gd')
var iOSExportTemplate = stc.get_gdscript('xcode/ios_export_template.gd')
var Team = stc.get_gdscript('xcode/team.gd')
var Provision = stc.get_gdscript('xcode/provision.gd')
var Device = stc.get_gdscript('xcode/device.gd')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
#                                Setters and Getters
# ------------------------------------------------------------------------------


var template setget ,get_template
func get_template():
	if template == null:
		template = iOSExportTemplate.new()
	return template


# ------------------------------------------------------------------------------
#                                Setter and Getters
# ------------------------------------------------------------------------------


var finder = stc.get_gdscript('xcode/finders/finder.gd') setget ,get_finder
func get_finder(): return finder


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func make_project_async(bundle_id=null, display_name=null):
	"""
	Async make xcode project.

	@return @see copy_install_async
	@return OK when attempt is good
	"""
	var template = get_template()
	if template.is_connected('copy_installed', self, '_on_template_copy_installed'):
		template.disconnect('copy_installed', self, '_on_template_copy_installed')
	template.connect('copy_installed', self, '_on_template_copy_installed', [bundle_id, display_name], CONNECT_ONESHOT)

	if template.copy_exists():
		_made_project(template, null, bundle_id, display_name)
	else:
		template.copy_install_async()



func _made_project(template, result, bundle_id, display_name):
	var project = Project.new()
	project.bundle_id = bundle_id
	project.name = display_name
	project.open(template.get_destination_path())

	emit_signal('made_project', self, result, project)


# ------------------------------------------------------------------------------
#                                     Callbacks
# ------------------------------------------------------------------------------


func _on_template_copy_installed(template, result, bundle_id, display_name):
	# TODO: For now, assume copy succeeded if this callback has been called.
	_made_project(template, result, bundle_id, display_name)
