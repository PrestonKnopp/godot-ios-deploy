# team_finder.gd
extends 'finder.gd'


# ------------------------------------------------------------------------------
#                                   Inner Classes
# ------------------------------------------------------------------------------


class Team:
	var id
	var name
	var account
	var type
	var is_free_account
	# func get_provisions():


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func find():
	var res = _sh.run(stc.get_shell_script(stc.shell.listteamsjson))
	if res.code != 0:
		_log.error('failed to convert teams to json', _log_mod)
		_log.error('\t%s'%res.output, _log_mod)
		return []

	_json.parse(res.output[0])
	if _json.get_result().error != OK:
		_log.error('Failed to parse team json', _log_mod)
		_log.error('\t'+str(_json.get_result().error)+' :: '+_json.get_result().error_string, _log_mod)
		return []

	var teams = []
	for key in _json.keys():
		var team = Team.new()
		team.account = key
		teams.append(team)
		for team_obj in _json.get_value(key):
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
