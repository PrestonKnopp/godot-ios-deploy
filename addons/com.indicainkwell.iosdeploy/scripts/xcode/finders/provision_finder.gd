# provision_finder.gd
extends 'finder.gd'


# ------------------------------------------------------------------------------
#                                     Subtypes
# ------------------------------------------------------------------------------


var Provision = stc.get_gdscript('xcode/provision.gd')


# ------------------------------------------------------------------------------
#                                Setters and Getters
# ------------------------------------------------------------------------------



var _provisions_path = OS.get_environment('HOME').plus_file('Library/MobileDevice/Provisioning Profiles')
func get_provisions_path():
	return _provisions_path


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func find():
	var prov_path = get_provisions_path()

	var dir = Directory.new()
	var err = dir.open(prov_path)
	if err != OK:
		_log.error('%s: failed to open %s'%[err,prov_path])
		return []

	err = dir.list_dir_begin()
	if err != OK:
		_log.error('%s: failed to list dir %s'%[err,prov_path])
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
			_log.info('Failed to convert provision<%s> to json'%file)
			continue

		var json = Json.new().parse(res.output[0])
		if json.get_result().error != OK:
			_log.info('Failed to parse provision<%s> json'%file)
			_log.info('\t%s'%json.get_result().error_string)
			continue

		var provision = Provision.new()
		provision.id = json.get_value('UUID', '')
		provision.name = json.get_value('Name', '[--No Name--]')
		provision.app_id = json.get_value('Entitlements/application-identifier', '')
		provision.app_id_name = json.get_value('AppIDName', '')
		provision.bundle_id = provision.app_id.right(provision.app_id.find('.') + 1)
		provision.xcode_managed = json.get_value('IsXcodeManaged', false)
		provision.platforms = json.get_value('Platform', [])
		provision.team_ids = json.get_value('TeamIdentifier', [])
		provision.team_name = json.get_value('TeamName', '')
		provision.creation_date = _date_parse(json.get_value('CreationDate'))
		provision.expiration_date = _date_parse(json.get_value('ExpirationDate'))

		provisions.append(provision)
	
	return provisions


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func _date_make_dict(year=0, month=0, day=0, hour=0, mint=0, sec=0):
	return {
		year = year,
		month = month,
		day = day,
		hour = hour,
		minute = mint,
		second = sec
	}


# Provision Profile Date Format: YYYY-MM-DDThh:mm:ssTZD
func _date_parse(date):
	if date == null or date.empty():
		return _date_make_dict()
	var reg = stc.get_gdscript('regex.gd').new()
	var err = reg.compile("(\\d{4})-(\\d{2})-(\\d{2})T(\\d{2}):(\\d{2}):(\\d{2})")
	assert(err == OK)
	var captures = reg.search(date)
	assert(captures.size() == 7) # 6 groups + whole group
	return _date_make_dict(
		int(captures[1]),
		int(captures[2]),
		int(captures[3]),
		int(captures[4]),
		int(captures[5]),
		int(captures[6])
	)
