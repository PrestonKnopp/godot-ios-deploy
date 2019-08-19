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
#                                   Dependencies
# ------------------------------------------------------------------------------


var PList = stc.get_gdscript('xcode/plist.gd')
var PBX = stc.get_gdscript('xcode/pbx.gd')
var Project = stc.get_gdscript('xcode/project.gd')
var iOSExportTemplate = stc.get_gdscript('xcode/ios_export_template.gd')
var Team = stc.get_gdscript('xcode/team.gd')
var Provision = stc.get_gdscript('xcode/provision.gd')
var Device = stc.get_gdscript('xcode/device.gd')
var Finder = stc.get_gdscript('xcode/finders/finder_umbrella.gd')


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


var finder = Finder.new() setget ,get_finder
func get_finder(): return finder


var project setget ,get_project
func get_project(): return project


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func is_project_ready():
	return project != null


func make_project_async():
	"""
	Async make xcode project.

	@return @see copy_install_async
	@return OK when attempt is good
	"""
	var template = get_template()
	if template.is_connected('copy_installed', self, '_on_template_copy_installed'):
		template.disconnect('copy_installed', self, '_on_template_copy_installed')
	template.connect('copy_installed', self, '_on_template_copy_installed', [], CONNECT_ONESHOT)

	# Remove outdated template copy
	if template.copy_exists() and not template.is_copy_version_valid():
		var err = template.copy_remove()
		var dst = template.get_destination_path()
		if err != OK:
			stc.get_logger().error(
				'Error<%s> Failed to remove old template copy %s' % [
					err, dst
				])
		else:
			stc.get_logger().info('Removed old template copy %s ' % [dst])
	
	if template.copy_exists():
		_made_project(template, null)
	else:
		template.copy_install_async()



func _made_project(template, result):
	project = Project.new()
	project.open(template.get_destination_path())

	emit_signal('made_project', self, result, project)


# ------------------------------------------------------------------------------
#                                     Callbacks
# ------------------------------------------------------------------------------


func _on_template_copy_installed(template, result):
	# TODO: For now, assume copy succeeded if this callback has been called.
	_made_project(template, result)
