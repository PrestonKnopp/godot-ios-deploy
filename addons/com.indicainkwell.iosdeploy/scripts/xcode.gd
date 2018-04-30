# xcode.gd
#
# TODO: test this
# TODO: major refactor
#  - [ ] Create a project maker class
#  - [X] Maybe a factory class for finding devices, provisions, and teams
#  - [X] Implement new classes
#  - [X] Classes for plist and pbxproj
#  - [X] Use a logger
extends Reference


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const stc = preload('static.gd')


# ------------------------------------------------------------------------------
#                                   Inner Classes
# ------------------------------------------------------------------------------


class Project:
	var team
	var provision
	var automanaged
	var bundle_id
	var path
	var name


# ------------------------------------------------------------------------------
#                                     Subtypes
# ------------------------------------------------------------------------------


var PList = stc.get_gdscript('xcode/plist.gd')
var PBX = stc.get_gdscript('xcode/pbx.gd')


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
func make_project(bundle_id, name, path):
	if stc.get_version().is2():
		return _make_project_v2(bundle_id, name, path)
	else:
		return _make_project_v3(bundle_id, name, path)


func _make_project_v2(bundle_id, name, path):

	var project = Project.new()
	
	var templates_path = stc.get_data_templates_dir_path()
	var dst_template = stc.get_data_template_path()
	var src_template = stc.get_ios_export_template_path()

	var pbxproj_path = dst_template.plus_file('godot_ios.xcodeproj/project.pbxproj')
	var info_plist_path = dst_template.plus_file('godot_ios/godot_ios-Info.plist')

	# First unzip Godot's distributed xcode ios templates
	# if it hasn't already

	if not Directory.new().dir_exists(dst_template):

		# NOTE: 2.0 unzips as a folder
		#       3.0 unzips as all files
		# unzip into templates path and rename resulting folder
		

		var globalized_templates_path = stc.globalize_path(templates_path)
		print('Unzipping %s to %s' % [src_template, globalized_templates_path])
		var sh_res = _shell.execute('unzip', [src_template, '-d', globalized_templates_path])

		var unzip_path = templates_path.plus_file('godot_ios_xcode')
		var err = Directory.new().rename(unzip_path, dst_template)
		if err != OK:
			print('Error<%s> renaming %s to %s' % [err, unzip_path, dst_template])

		# -- Don't need to do this; plutil can convert pbxproj directly to json
		# # convert pbxproj to plist format
		# # Xcode can still read pbxproj in plist format
		# sh_res = _sh.run(stc.shell.cvtpbxproj2plist, pbxproj_path)
		# if sh_res.output.size() > 0 and sh_res.output[0].length() > 0:
		# 	print(sh_res.output[0])
	
	# Update project info -- same for both v3 and v2

	_update_info_plist(info_plist_path, name, bundle_id)
	_update_pbxproj(pbxproj_path, name, path)

	# fill project struct

	project.bundle_id = bundle_id
	project.name = name
	project.path = dst_template

	return project


func _make_project_v3(bundle_id, name, path):
	# get path to xcode project export template
	# how to choose which template version to get?
	# Gen your own project. don't build from godot command line.
	# Use template for libgodot
	pass


func _update_pbxproj(pbxproj_path, name, path):
	
	var pbx = PBX.new()
	if pbx.open(pbxproj_path) != OK:
		return
	
	# Steps:
	# 1. Add project file ref as PBXFileReference
	#   - isa = PBXFileReference
	#   - lastKnownFileType = folder
	#   - name = project name
	#   - path = "relative path"
	# 2. Add project as PBXBuildFile
	#   - isa = PBXBuildFile
	#   - fileRef = the above
	# 3. Add file ref to PBXGroup without name ie root group
	#   - isa = PBXGroup
	#   - children = array of ids
	# 4. Add build file to PBXResourcesBuildPhase
	#   - isa = PBXResourcesBuildPhase
	#   - files = array of ids
	var project_file_ref_uuid = 'DEADDEADDEADDEADDEADDEAD'
	var project_build_file_uuid = 'BEEFBEEFBEEFBEEFBEEFBEEF'

	pbx.add_object(project_file_ref_uuid, 'PBXFileReference', {
		lastKnownFileType = 'folder',
		name = name,
		path = path,
	})

	pbx.add_object(project_build_file_uuid, 'PBXBuildFile', {
		fileRef = project_file_ref_uuid,
	})

	var root_pbxgroup_q = PBX.Query.new()
	root_pbxgroup_q.type = 'PBXGroup'
	root_pbxgroup_q.excludekeypath = 'name'
	
	var resource_build_phase_q = PBX.Query.new()
	resource_build_phase_q.type = 'PBXResourcesBuildPhase'

	var res = pbx.find_objects([root_pbxgroup_q, resource_build_phase_q])
	assert(res[0].size() == 1)
	assert(res[1].size() == 1)
	res[0]['children'].append(project_file_ref_uuid)
	res[1]['files'].append(project_build_file_uuid)

	pbx.save_plist(pbxproj_path)



func _update_info_plist(info_plist_path, name, bundle_id):
	
	var plist = Plist.new()
	if plist.open(info_plist_path) != OK:
		return
	
	plist.set_value("CFBundleDisplayName", name)
	plist.set_value("CFBundleDisplayIdentifier", bundle_id)
	plist.set_value("godot_path", name)
	
	plist.save()
