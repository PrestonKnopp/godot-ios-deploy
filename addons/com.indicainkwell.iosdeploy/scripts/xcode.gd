extends Reference

# TODO: test this
# TODO: major refactor

const stc = preload('static.gd')

var Shell = stc.get_gdscript('shell.gd')
var Json = stc.get_gdscript('json.gd')


class Device:
	enum Type {
		Unknown,
		iPhone,
		iPad,
		Simulator,
		Mac
	}
	
	var id
	var name
	var type


class Team:
	var id
	var name
	var account
	var type
	var is_free_account
	# func get_provisions():


class Provision:
	var id
	var name
	var app_id_name
	#var entitlements
	var platforms
	var team_ids


class Project:
	var team
	var provision
	var automanaged
	var bundle_id
	var name
	# func get_path():
	# func build():
	# func built():


var _shell = Shell.new()
var _sh = _shell.make_command('/bin/bash')


func get_teams():
	
	var res = _sh.run(stc.get_shell_script(stc.shell.listteamsjson))
	if res.code != 0: 
		return []
	
	var json = Json.new().parse(res.output[0])
	if json.get_result().error != OK:
		printerr(json.get_result().error, ' :: ', json.get_result().error_string)
		return []
	
	var teams = []
	for key in json.keys():
		var team = Team.new()
		team.account = key
		teams.append(team)
		for team_obj in json.get_value(key):
			if team_obj.has('teamID'):
				team.id = team_obj['teamID']
			if team_obj.has('teamName'):
				team.name = team_obj['teamName']
			if team_obj.has('teamType'):
				team.type = team_obj['teamType']
			if team_obj.has('isFreeProvisioningTeam'):
				var is_free = team_obj['isFreeProvisioningTeam']
				team.is_free_account = true
				if is_free == '0':
					team.is_free_account = false
	return teams


func get_provisions():
	
	var dir = Directory.new()
	var prov_path = stc.get_provisions_path()
	if not dir.dir_exists(prov_path):
		return []
	
	var err = dir.open(prov_path)
	if err != OK:
		return []
	
	err = dir.list_dir_begin()
	if err != OK:
		dir.list_dir_end()
		return []
	
	var prov2json = stc.get_shell_script(stc.shell.provision2json)
	var provisions = []
	
	var cur = dir.get_next()
	while cur != '':
		var file = cur
		cur = dir.get_next()
		if file.begins_with('.'):
			continue
		
		var res = _sh.run(prov2json, prov_path.plus_file(file))
		if res.code != 0:
			continue
		
		var json = Json.new().parse(res.output[0])
		if json.get_result().error != OK:
			continue
		
		var provision = Provision.new()
		provision.id = json.get_value('UUID', '')
		provision.name = json.get_value('Name', 'No Name')
		provision.app_id_name = json.get_value('AppIDName', '')
		provision.platforms = json.get_value('Platform', [])
		provision.team_ids = json.get_value('TeamIdentifier', [])
		
		provisions.append(provision)
	
	return provisions


# TODO: use ios-deploy to get devices, it's faster than instruments
func get_devices():
	
	var listknowndevices = stc.get_shell_script(stc.shell.listknowndevices)
	var res = _sh.run(listknowndevices)
	if res.code != 0:
		return []
	
	var devices = []
	
	# for some reason multiline output is all in first element
	for line in res.output[0].split('\n', false):
		# skip sims until add support for x86 project gen
		if line.find('] (Simulator)') != -1:
			continue
		
		var device = Device.new()
		var end_name_idx = line.rfind('[')
		device.name = line.substr(0, end_name_idx).strip_edges()
		
		
		var end_id_idx = line.find(']', end_name_idx)
		
		# move passed '['
		end_name_idx += 1
		
		var id_length = end_id_idx - end_name_idx
		device.id = line.substr(end_name_idx, id_length)
		
		device.type = device.Type.Unknown
		if device.name.findn('macbook') != -1:
			device.type = device.Type.Mac
		elif device.name.findn('iphone') != -1:
			device.type = device.Type.iPhone
		elif device.name.findn('ipad') != -1:
			device.type = device.Type.iPad
		
		devices.append(device)
	return devices



# TODO: handle not having templates installed
func make_project(bundle_id, name, path, team, provision, automanaged):
	if stc.get_version().is2():
		return _make_project_v2(bundle_id, name, team, provision, automanaged)
	else:
		return _make_project_v3(bundle_id, name, team, provision, automanaged)


func _make_project_v2(bundle_id, name, path, team, provision, automanaged):

	var sh_res = null

	var templates_path = stc.get_data_templates_dir_path()
	var dst_template = stc.get_data_template_path()
	var src_template = stc.get_ios_export_template_path()

	var pbxproj_path = dst_template.plus_file('godot_ios.xcodeproj/project.pbxproj')

	# First unzip Godot's distributed xcode ios templates
	# if it hasn't already

	if not Directory.new().dir_exists(templates_path):
	
		# NOTE: 2.0 unzips as a folder
		#       3.0 unzips as all files
		# unzip into templates path and rename resulting folder
		Shell.execute('unzip', [src_template, '-d', templates_path])

		var unzip_path = templates_path.plus_file('godot_ios_xcode')
		err = dir.rename(unzip_path, dst_template)
		if err != OK:
			print('Error<%s> renaming %s to %s' % [err, unzip_path, dst_template])
		
		# convert pbxproj to plist format
		# Xcode can still read pbxproj in plist format
		sh_res = _sh.run(stc.shell.cvtpbxproj2plist, pbxproj_path)
		if sh_res.output.size() > 0 and sh_res.output[0].length() > 0:
			print(sh_res.output[0])
	
	# Update Info.plist

	var pbuddy = Shell.make_command('/usr/libexec/PlistBuddy')
	var pbuddyargs = []

	# TODO: get name of project from globals
	var keys = {
		CFBundleDisplayName = name,
		CFBundleDisplayIdentifier = bundle_id,
		godot_path = name
	}

	for key in keys:
		pbuddyargs.append('-c')
		pbuddyargs.append('Set %s %s' % [key,keys[key]])
	
	sh_res = pbuddy.run(pbuddyargs, dst_template.plus_file('godot_ios/godot_ios-Info.plist'))
	if sh_res.output.size() > 0 and sh_res.output[0].length() > 0:
		print(sh_res.output[0])

	# Update pbxproj
	
	sh_res = _sh.run(stc.shell.plist2json, pbxproj_path)
	var json = Json.new().parse(sh_res.output[0])
	if json.get_result().error != OK:
		print('Error parsing json: ', json.get_result().error_string)

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
	var objects = json.get_value('objects')

	objects[project_file_ref_uuid] = {
		isa = 'PBXFileReference',
		lastKnownFileType = 'folder',
		name = name,
		path = path,
	}

	objects[project_build_file_uuid] = {
		isa = 'PBXBuildFile',
		fileRef = project_file_ref_uuid,
	}

	for key in objects.keys():
		var object = objects[key]
		if object['isa'] == 'PBXGroup' and not object.has('name'):
			# add file ref to root pbxgroup
			object['children'].append(project_file_ref_uuid)
		elif object['isa'] == 'PBXResourcesBuildPhase':
			# add build file to build resources
			object['files'].append(project_build_file_uuid)
	
	sh_res = _sh.run(stc.shell.json2plist, json.to_string(), pbxproj_path)
	if sh_res.code != 0:
		print('Failed to convert json2plist', sh_res.output)


	# Create a project struct

	var project = Project.new()
	project.team = team
	project.provision = provision
	project.automanaged = automanaged
	project.bundle_id = bundle_id
	project.name = name

	return project


func _make_project_v3(bundle_id, name, path, team, provision, automanaged):
	# get path to xcode project export template
	# how to choose which template version to get?
	# Gen your own project. don't build from godot command line.
	# Use template for libgodot
	pass
