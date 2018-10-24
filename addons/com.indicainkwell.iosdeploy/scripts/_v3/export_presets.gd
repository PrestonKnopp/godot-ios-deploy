# _v3/export_presets.gd
tool
extends '../export_presets.gd'


var PoolStringConverter = stc.get_gdscript('pool_string_converter.gd')


func _make_runnable_ios_preset_structure(presets):

	# Fill all sections to avoid config.get_value error from godot

	# section names

	var id = _find_next_section_id(presets)
	var preset = 'preset.' + id
	var preset_options = preset + '.options'

	# preset
	
	var preset_vars = [
		{'name' : "iOS"},
		{'platform' : "iOS"},
		{'runnable' : true},
		{'custom_features' : ""},
		{'export_filter' : "all_resources"},
		{'include_filter' : ""},
		{'exclude_filter' : ""},
		{'patch_list' : PoolStringConverter.convert_array([])},
	]
	for v in preset_vars:
		for key in v:
			presets.set_value(preset, key, v[key])

	# options

	var preset_option_vars = [
		{'custom_package/debug' : ""},
		{'custom_package/release' : ""},
		{'application/app_store_team_id' : ""},
		{'application/provisioning_profile_uuid_debug' : ""},
		{'application/code_sign_identity_debug' : "iPhone Developer"},
		{'application/export_method_debug' : 1},
		{'application/provisioning_profile_uuid_release' : ""},
		{'application/code_sign_identity_release' : "iPhone Distribution"},
		{'application/export_method_release' : 0},
		{'application/name' : ""},
		{'application/info' : "Made with Godot Engine"},
		{'application/identifier' : "org.godotengine.iosgame"},
		{'application/signature' : "????"},
		{'application/short_version' : "1.0"},
		{'application/version' : "1.0"},
		{'application/copyright' : ""},
		{'required_icons/iphone_120x120' : ""},
		{'required_icons/ipad_76x76' : ""},
		{'required_icons/app_store_1024x1024' : ""},
		{'optional_icons/iphone_180x180' : ""},
		{'optional_icons/ipad_152x152' : ""},
		{'optional_icons/ipad_167x167' : ""},
		{'optional_icons/spotlight_40x40' : ""},
		{'optional_icons/spotlight_80x80' : ""},
		{'landscape_launch_screens/iphone_2436x1125' : ""},
		{'landscape_launch_screens/iphone_2208x1242' : ""},
		{'landscape_launch_screens/ipad_1024x768' : ""},
		{'landscape_launch_screens/ipad_2048x1536' : ""},
		{'portrait_launch_screens/iphone_640x960' : ""},
		{'portrait_launch_screens/iphone_640x1136' : ""},
		{'portrait_launch_screens/iphone_750x1334' : ""},
		{'portrait_launch_screens/iphone_1125x2436' : ""},
		{'portrait_launch_screens/ipad_768x1024' : ""},
		{'portrait_launch_screens/ipad_1536x2048' : ""},
		{'portrait_launch_screens/iphone_1242x2208' : ""},
		{'texture_format/s3tc' : false},
		{'texture_format/etc' : false},
		{'texture_format/etc2' : true},
		{'architectures/armv7' : true},
		{'architectures/arm64' : true},
	]
	for v in preset_option_vars:
		for key in v:
			presets.set_value(preset_options, key, v[key])


func _find_next_section_id(presets):
	var sections = presets.get_sections()
	var size = sections.size()
	var last_section = sections[size-1] if size>0 else null
	if last_section == null:
		return '0'
	var parts = last_section.split('.')
	if parts.size() >= 2:
		return parts[1]
	# screw it, go for it
	return '0'

func _init_presets():
	var presets = ConfigFile.new()
	var err = presets.load('res://export_presets.cfg')
	if err != OK:
		stc.get_logger().info('could not open export_presets.cfg')
		_make_runnable_ios_preset_structure(presets)
	
	var opts_sect = _find_runnable_ios_preset_options_section(presets)
	if opts_sect == null:
		_make_runnable_ios_preset_structure(presets)
		opts_sect = _find_runnable_ios_preset_options_section(presets)
	
	return {presets = presets, section = opts_sect}


func _wrap_up(presets):
	presets.save('res://export_presets.cfg')


func fill():
	var res = _init_presets()

	var cfg = stc.get_config()
	_fill(
		res.presets, cfg,
		res.section, 'application/app_store_team_id',
		'xcode/project', 'team',
		true
	)
	_fill(
		res.presets, cfg,
		res.section, 'application/provisioning_profile_uuid_debug',
		'xcode/project', 'provision',
		true
	)
	_fill(
		res.presets, cfg,
		res.section, 'application/name',
		'xcode/project', 'name',
		false
	)

	_wrap_up(res.presets)


func _find_runnable_ios_preset_options_section(presets):
	for section in presets.get_sections():
		if presets.get_value(section, 'platform') == 'iOS' and\
		   presets.get_value(section, 'runnable'):
			return section + '.options'
	return null


func _fill(presets, cfg, opt_sect, opt_key, cfg_sect, cfg_key, with_id):
	var opt = cfg.get_value(cfg_sect, cfg_key, null)
	if opt == null or (with_id and opt.id == null):
		return
	var val = opt.id if with_id else opt
	presets.set_value(opt_sect, opt_key, val)
