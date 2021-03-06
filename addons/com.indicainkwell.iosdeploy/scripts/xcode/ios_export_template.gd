# ios_export_template.gd
extends Reference


# ------------------------------------------------------------------------------
#                                      Signals
# ------------------------------------------------------------------------------


signal copy_installed(this, result)
signal copy_install_failed(this, error)


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const stc = preload('../static.gd')


const TEMPLATE_NAME = {
	V2 = 'GodotiOSXCode.zip',
	V3 = 'iphone.zip',
}


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var _shell = stc.get_gdscript('shell.gd').new()
var _unzip = _shell.make_command('unzip')

var _log = stc.get_logger().make_module_logger(stc.PLUGIN_DOMAIN + '.ios-export-template')


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func get_existing_zip_path():
	"""
	@returns String
	  Path to existing zip or null if it does not exist.
	"""
	var f = File.new()
	for path in get_possible_zip_paths():
		if f.file_exists(path):
			_log.info('Zip Path Exists: ' + path)
			return path
	return null


func get_possible_zip_paths():
	"""
	Returns the possible path variations to the current godot's version ios
	xcode template zip.
	"""
	var home = OS.get_environment('HOME')

	var v = stc.get_version()
	if v.is2():
		return [home.plus_file('.godot/templates')\
		       .plus_file(TEMPLATE_NAME.V2)]
	else:
		var tnames = [
			'%s.%s.%s.%s' % [ v.get_major(), v.get_minor(),
				v.get_patch(), v.get_status() ],
			'%s.%s.%s' % [ v.get_major(), v.get_minor(),
				v.get_status() ],
			'%s.%s-%s' % [ v.get_major(), v.get_minor(),
				v.get_status() ],
		]
		var storage_paths = [
			home.plus_file('Library/Application Support/Godot/templates'),
			OS.get_environment('XDG_DATA_HOME').plus_file('Godot/templates')
		]
		var paths = []
		for storage_path in storage_paths:
			for template_name in tnames:
				var path = storage_path\
				       .plus_file(template_name)\
				       .plus_file(TEMPLATE_NAME.V3)
				paths.append(path)
		_log.info('Possible iOS Export Template zip paths: ' + str(paths))
		return paths


func get_destination_path(make_dir=false, make_template_file_dir=true):
	"""
	Get destination path for copied ios export template.

	Defaults to not making directory.

	Why make_template_file_dir? V3 export template unzips as all of it's
	containing files while V2 unzips as a folder.

	So V2 would need make_template_file_dir=false.
	"""
	# user://<domain>/templates/<version>/{GodotiOSXCode.zip,iphone.zip}
	var v = stc.get_version()

	# tdir is template data dir
	var tdir = stc.get_data_path('templates'.plus_file(v.get_string()))

	# tpath is data dir with template file name, also a dir
	var tpath
	if v.is2():
		tpath = tdir.plus_file(TEMPLATE_NAME.V2)
	else:
		tpath = tdir.plus_file(TEMPLATE_NAME.V3)

	var path
	if make_template_file_dir:
		path = tpath
	else:
		path = tdir

	if make_dir:
		var d = Directory.new()
		if not d.dir_exists(path):
			var err = d.make_dir_recursive(path)
			if err != OK:
				_log.error('Error<%s> making path<%s>' % [err,path])

	return stc.globalize_path(tpath)


# ------------------------------------------------------------------------------
#                          iOS Xcode Template Copy Actions
# ------------------------------------------------------------------------------


func is_copy_version_valid():
	"""
	Check if config's version matches current version.
	"""
	# ios_export_template changed in cfg ver == 1
	return stc.CONFIG_VERSION >= 1 and not stc.get_config().version_differed_on_startup()


func copy_exists():
	"""
	Check if copy has already been made by us.
	"""
	return Directory.new().dir_exists(get_destination_path())


func copy_remove():
	"""
	Remove copy of xcode template.
	"""
	# TODO: abstract this out
	var d = Directory.new()
	var trashed = OS.get_environment('HOME').plus_file('.Trash')
	trashed = trashed.plus_file('OldGodotXcodeTemplateCopy')
	var i = 0
	while d.dir_exists(trashed + str(i)):
		i += 1
	trashed += str(i)
	return d.rename(get_destination_path(), trashed)


func copy_install_async():
	"""
	Async install copy of xcode template for deploy.
	@emits copy_install_failed, copy_installed
	"""
	var zip_path = get_existing_zip_path()
	if zip_path != null:
		if stc.get_version().is2():
			_copy_ios_export_template_v2(zip_path)
		else:
			_copy_ios_export_template_v3(zip_path)
	else:
		_log.error('Godot iOS Xcode Template not installed.')
		emit_signal('copy_install_failed', self, ERR_DOES_NOT_EXIST)


# ------------------------------------------------------------------------------
#                               Copy Install Version
# ------------------------------------------------------------------------------


func _copy_ios_export_template_v2(zip_path):
	# V2 unzips from GodotiOSXCode.zip to godot_ios_xcode
	#
	# Steps:
	# 1. unzip to destination
	# 2. rename from godot_ios_xcode -> GodotiOSXCode.zip
	var args = [
		zip_path,
		'-d',
		get_destination_path(true, false).get_base_dir()
	]
	_unzip.run_async(args, self, '_on_v2_unzip_finished')


func _copy_ios_export_template_v3(zip_path):
	# V3 unzips from iphone.zip to all of its files
	#
	# Steps:
	# 1. unzip to destination
	var args = [
		zip_path,
		'-d',
		get_destination_path(true)
	]
	_unzip.run_async(args, self, '_on_v3_unzip_finished')


# ------------------------------------------------------------------------------
#                                     Callbacks
# ------------------------------------------------------------------------------


func _on_v2_unzip_finished(command, result):
	_log.info('UNZIP LOG: %s' % result.get_stdout_string())

	var dst = get_destination_path(true, false)
	var unzip_dst = dst.get_base_dir().plus_file('godot_ios_xcode')
	var err = Directory.new().rename(unzip_dst, dst)
	if err != OK:
		_log.error('Error<%s> renaming ios export template from %s to s'%[ err, unzip_dst, dst ])
	emit_signal('copy_installed', self, result)


func _on_v3_unzip_finished(command, result):
	_log.info('UNZIP LOG: %s' % result.get_stdout_string())

	var d = Directory.new()
	var f = File.new()
	var err

	# rename libgodot.*.a to default.template.libgodot.*.a
	for build in ['debug', 'release']:
		var libpath = get_destination_path().plus_file('libgodot.iphone.%s.fat.a' % build)
		var dstpath = get_destination_path().plus_file(stc.DEFAULT_TEMPLATE_LIB_NAME_FMT % build)
		err = d.rename(libpath, dstpath)
		if err != OK:
			_log.error('failed with code %s to rename %s to s'%[err,libpath,dstpath])
		_log.info('Renamed %s to %s'%[libpath,dstpath])
	
	# rename data.pck to godot_ios.pck
	var srcpck = get_destination_path().plus_file('data.pck')
	var dstpck = get_destination_path().plus_file('godot_ios.pck')
	err = d.rename(srcpck, dstpck)
	if err != OK:
		_log.error('failed with code %s to rename %s to s'%[err,srcpck,dstpck])
	_log.info('Renamed %s to %s'%[srcpck,dstpck])

	# make Image.xcassets/AppIcon.appiconset
	var xcassets = get_destination_path().plus_file('godot_ios/Images.xcassets/AppIcon.appiconset')
	err = d.make_dir_recursive(xcassets)
	if err != OK:
		_log.error('failed with code %s to makedir %s'%[err,xcassets])
	_log.info('Made directory %s'%xcassets)

	# clear dummy.cpp
	f.open(get_destination_path().plus_file('godot_ios/dummy.cpp'), File.WRITE)
	f.close()
	_log.info('Cleared dummy.cpp')

	# fill in info.plist
	var plist = get_destination_path().plus_file('godot_ios/godot_ios-Info.plist')
	if f.open(plist, File.READ) == OK:
		var edited_plist = ''
		while not f.eof_reached():
			var line = f.get_line()\
			            .replace('$name', '${PRODUCT_NAME}')\
			            .replace('$binary', 'godot_ios')\
			            .replace('$short_version', '1.0')\
			            .replace('$version', '1.0')\
			            .replace('$signature', '????')
			# skip extra plist expansion
			if line.strip_edges(true, false).begins_with('$'):
				continue
			edited_plist += line + '\n'
		f.close()

		if f.open(plist, File.WRITE) == OK:
			f.store_string(edited_plist)
			f.close()
		else:
			_log.error('failed with code %s to write edits to %s'%[f.get_error(),plist])
	else:
		_log.error('failed with code %s to open %s for editing'%[f.get_error(),plist])
	_log.info('Edited %s'%plist)

	# strip out expansion variables from pbxproject
	var pbx = get_destination_path().plus_file('godot_ios.xcodeproj/project.pbxproj')
	if f.open(pbx, File.READ) == OK:

		var edited_pbx = ''
		while not f.eof_reached():
			var line = f.get_line()\
			            .replace('$binary', 'godot_ios')\
			            .replace('$linker_flags', '')\
			            .replace('$godot_archs', '$(ARCHS_STANDARD_INCLUDING_64_BIT)')\
			            .replace('$code_sign_identity_release', 'iPhone Developer')\
			            .replace('$code_sign_identity_debug', 'iPhone Developer')
			            # TODO: ^ should be options set via xcode project build
			
			if line.find('CODE_SIGN_ENTITLEMENTS = godot_ios/godot_ios.entitlements;') > -1:
				# TODO: ... ignore entitlements for now
				continue
			if line.find('$') > -1 and\
			   line.strip_edges(true, false).begins_with('$'):
				continue
			edited_pbx += line + '\n'
		f.close()

		if f.open(pbx, File.WRITE) == OK:
			f.store_string(edited_pbx)
			f.close()
		else:
			_log.error('failed with code %s to write edits to s'%[f.get_error(), pbx])

	else:
		_log.error('failed with code %s to open %s for editing'%[f.get_error(),pbx])
	_log.info('Edited %s'%pbx)

	emit_signal('copy_installed', self, result)
