# team_finder.gd
extends 'Finder.gd'


# ------------------------------------------------------------------------------
#                                     Subtypes
# ------------------------------------------------------------------------------


var Team = stc.get_gdscript('xcode/team.gd')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var _listteamsjson_thread_id = -1


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func begin_find():
	if _sh.running(_listteamsjson_thread_id):
		# no need to run again
		return
	_listteamsjson_thread_id = _sh.run_async(
		[stc.get_shell_script(stc.shell.listteamsjson)],
		self,
		'_on_listteamsjson_finished'
	)


func _on_listteamsjson_finished(command, result):
	if result.code != 0:
		_log.error('failed to convert teams to json')
		_log.error('\t'+result.output)
		_finished([])
		return

	_json.parse(result.output[0])
	if _json.get_result().error != OK:
		_log.error('Failed to parse team json')
		_log.error('\t'+str(_json.get_result().error)+' :: '+_json.get_result().error_string)
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

	_listteamsjson_thread_id = -1
	_finished(teams)
