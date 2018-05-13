# xcode.gd
extends Reference


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


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
#                                Setter and Getters
# ------------------------------------------------------------------------------


var finder = stc.get_gdscript('xcode/finders/finder.gd') setget ,get_finder
func get_finder(): return finder


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------




# TODO: handle not having templates installed
func make_project(bundle_id=null, display_name=null):
	var template = iOSExportTemplate.new()
	if not template.copy_exists():
		template.copy_install()
	
	var project = Project.new()
	project.bundle_id = bundle_id
	project.name = display_name
	project.open(template.get_destination_path())

	return project

