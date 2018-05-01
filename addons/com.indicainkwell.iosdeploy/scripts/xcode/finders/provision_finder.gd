# provision_finder.gd
extends 'finder.gd'


# ------------------------------------------------------------------------------
#                                   Inner Classes
# ------------------------------------------------------------------------------


class Provision:
	var id
	var name
	var app_id_name
	#var entitlements
	var platforms
	var team_ids


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func find():
	var prov_path = stc.get_provisions_path()

	var dir = Directory.new()
	var err = dir.open(prov_path)
	if err != OK:
		_log.error('%s: failed to open %s'%[err,prov_path], _log_mod)
		return []

	err = dir.list_dir_begin()
	if err != OK:
		_log.error('%s: failed to list dir %s'%[err,prov_path], _log_mod)
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
			_log.info('Failed to convert provision<%s> to json'%file,_log_mod)
			continue

		var json = Json.new().parse(res.output[0])
		if json.get_result().error != OK:
			_log.info('Failed to parse provision<%s> json'%file,_log_mod)
			continue

		var provision = Provision.new()
		provision.id = json.get_value('UUID', '')
		provision.name = json.get_value('Name', 'No Name')
		provision.app_id_name = json.get_value('AppIDName', '')
		provision.platforms = json.get_value('Platform', [])
		provision.team_ids = json.get_value('TeamIdentifier', [])

		provisions.append(provision)

	return provisions