# ios_export_template.gd
extends Reference


# ------------------------------------------------------------------------------
#                                      Signals
# ------------------------------------------------------------------------------


signal copy_installed(this, result)


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


func exists():
	"""
	Checks if Godot's iOS Export xcode template is installed
	"""
	return File.new().file_exists(get_zip_path())


func get_zip_path():
	"""
	Returns the path to the current godot's version ios xcode template zip.
	"""
	var home = OS.get_environment('HOME')

	var v = stc.get_version()
	if v.is2():
		return home.plus_file('.godot/templates')\
		       .plus_file(TEMPLATE_NAME.V2)
	else:
		# TODO: figure out what to do for 3.0 export templates
		# NOTE: Different template name formats
		#       - 3.0-stable/
		#       - 3.0.2.stable/ <-- use this one
		var tname = '%s.%s.%s.%s' % [
			v.get_major(),
			v.get_minor(),
			v.get_patch(),
			v.get_status()
		]
		return home\
		       .plus_file('Library/Application Support/Godot/templates')\
		       .plus_file(tname)\
		       .plus_file(TEMPLATE_NAME.V3)


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


func copy_exists():
	"""
	Check if copy used for ios-deploy exists.
	"""
	return Directory.new().dir_exists(get_destination_path())


func copy_remove():
	"""
	Remove copy of xcode template.
	"""
	return Directory.new().remove(get_destination_path())


func copy_install_async():
	"""
	Async install copy of xcode template for ios-deploy.

	@return ERR_DOES_NOT_EXIST
		When godot xcode template does not exist
	@return OK
		When able to attempt copy
	"""
	if not exists():
		_log.error('Godot iOS Xcode Template not installed.')
		return ERR_DOES_NOT_EXIST

	if stc.get_version().is2():
		_copy_ios_export_template_v2()
	else:
		_copy_ios_export_template_v3()

	return OK


# ------------------------------------------------------------------------------
#                               Copy Install Version
# ------------------------------------------------------------------------------


func _copy_ios_export_template_v2():
	# V2 unzips from GodotiOSXCode.zip to godot_ios_xcode
	#
	# Steps:
	# 1. unzip to destination
	# 2. rename from godot_ios_xcode -> GodotiOSXCode.zip
	var args = [
		get_zip_path(),
		'-d',
		get_destination_path(true, false).get_base_dir()
	]
	_unzip.run_async(args, self, '_on_v2_unzip_finished')


func _copy_ios_export_template_v3():
	# V3 unzips from iphone.zip to all of its files
	#
	# Steps:
	# 1. unzip to destination
	var args = [
		get_zip_path(),
		'-d',
		get_destination_path(true)
	]
	_unzip.run_async(args, self, '_on_v3_unzip_finished')


# ------------------------------------------------------------------------------
#                                     Callbacks
# ------------------------------------------------------------------------------


func _on_v2_unzip_finished(command, result):
	_log.info('UNZIP LOG: %s' % result.output[0])

	var dst = get_destination_path(true, false)
	var unzip_dst = dst.get_base_dir().plus_file('godot_ios_xcode')
	var err = Directory.new().rename(unzip_dst, dst)
	if err != OK:
		_log.error('Error<%s> renaming ios export template from %s to s'%[ err, unzip_dst, dst ])
	emit_signal('copy_installed', self, result)


func _on_v3_unzip_finished(command, result):
	_log.info('UNZIP LOG: %s' % result.output[0])

	var d = Directory.new()
	var f = File.new()
	var err

	# rename libgodot.debug.a to godot_ios.a
	var libpath = get_destination_path().plus_file('libgodot.iphone.debug.fat.a')
	var dstpath = get_destination_path().plus_file('godot_ios.a')
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
