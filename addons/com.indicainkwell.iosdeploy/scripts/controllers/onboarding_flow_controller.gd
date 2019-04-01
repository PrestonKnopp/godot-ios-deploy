# onboarding_flow_controller.gd
#
# Responds to input received from gui/onboarding_flow.gd and updates
# controller.gd accordingly.
#
# Implements onboarding validation logic.
#
# Be sure to set_xcode().
#
# TODO: get rid of get_parent() calls
# TODO: remove onboarding_flow automanage section
tool
extends 'Controller.gd'


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const _NONE = 0
const _PROVISION = 1
const _TEAM = 2


# ------------------------------------------------------------------------------
#                                      Scenes
# ------------------------------------------------------------------------------


var OnboardingFlowScene = stc.get_scene('onboarding_flow.tscn')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var _xcode
var _requesting = {
	results_mask = _NONE,
	count = 0,
	provisions_and_teams = false,
	just_teams = false,
}
var _teams_cache = []
var _provisions_cache = []


# ------------------------------------------------------------------------------
#                                  Node Overrides
# ------------------------------------------------------------------------------


func _enter_tree():
	view = OnboardingFlowScene.instance()
	view.connect('onboarded', self, '_on_onboarded')
	view.connect('populate', self, '_on_populate')
	view.connect('validate', self, '_on_validate')
	get_plugin().add_menu(view)


func _exit_tree():
	view.queue_free()


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func set_xcode(xcode):
	_xcode = xcode
	if not _xcode.finder.is_connected('result', self, '_on_xcode_finder_result'):
		_xcode.finder.connect('result', self, '_on_xcode_finder_result')


func _make_automanaged_provision_representation():
	var provision = _xcode.Provision.new()
	provision.name = 'Automanaged'
	provision.bundle_id = '*'
	provision.xcode_managed = true
	provision.team_ids = []

	for team in _teams_cache:
		provision.team_ids.append(team.id)
	
	return provision


func _request_teams():
	_requesting.count += 1
	_requesting.results_mask = _NONE
	_requesting.just_teams = true
	_xcode.finder.begin_find_teams()


func _request_provisions_and_teams():
	_requesting.count += 2
	_requesting.results_mask = _NONE
	_requesting.provisions_and_teams = true
	_xcode.finder.begin_find_teams()
	_xcode.finder.begin_find_provisions()


# ------------------------------------------------------------------------------
#                               Xcode Finder Callback
# ------------------------------------------------------------------------------


func _on_xcode_finder_result(finder, type, objects):
	if _requesting.count <= 0 or not type in [finder.Type.TEAM, finder.Type.PROVISION]:
		return
	
	if type == finder.Type.TEAM:
		_teams_cache = objects
		_requesting.results_mask |= _TEAM
	elif type == finder.Type.PROVISION:
		_provisions_cache = objects
		_requesting.results_mask |= _PROVISION
	
	_requesting.count -= 1
	
	var flow = get_view()
	if _requesting.provisions_and_teams and\
	   _requesting.results_mask == _TEAM | _PROVISION:
		
		_requesting.provisions_and_teams = false
		
		var provisions = [_make_automanaged_provision_representation()] +\
			get_parent().filter_provisions(_provisions_cache)
		
		flow.populate_option_section(flow.SECTION.PROVISION, provisions)
		if _xcode.project.provision != null:
			flow.provision = _xcode.project.provision
		elif provisions.size() > 0:
			flow.provision = provisions.front()
		flow.request_validation(flow.SECTION.PROVISION, flow.provision)
	
	if _requesting.just_teams and\
	   _requesting.results_mask & _TEAM == _TEAM:
		
		_requesting.just_teams = false
		
		var teams = _teams_cache
		var team = null
		
		if _xcode.project.team != null:
			team = _xcode.project.team
			# Add xcode project's current team to teams. This may
			# happen when begin_find_teams() doesn't find any teams,
			# but xcode_project has been loaded from saved config.
			if teams.size() == 0:
				teams.append(team)
		else:
			# Use the team set in the provision from this flow
			var team_id = flow.provision.team_ids.front()
			if team_id != null:
				var has_team_id = false
				for t in teams:
					if t.id == team_id:
						has_team_id = true
						team = t
						break
				if not has_team_id:
					team = _xcode.Team.new()
					team.id = team_id
					team.name = flow.provision.team_name
					teams.append(team)
		
		flow.populate_option_section(flow.SECTION.TEAM, teams)
		flow.team = team
		flow.request_validation(flow.SECTION.TEAM, team)


# ------------------------------------------------------------------------------
#                             Onboarding Flow Callbacks
# ------------------------------------------------------------------------------


func _on_populate(flow, section):
	if section == flow.SECTION.PROVISION:
		_request_provisions_and_teams()

	if section == flow.SECTION.AUTOMANAGE:
		flow.automanaged = _xcode.project.automanaged
	
	if section == flow.SECTION.TEAM:
		_request_teams()

	if section == flow.SECTION.DISPLAY_NAME:
		if _xcode.project.name != null:
			flow.display_name = _xcode.project.name
	
	if section == flow.SECTION.BUNDLE_ID:
		# Use saved _xcode.project.bundle_id when
		# - flow.provision == null
		# - flow.provision == project.provision
		# - flow.provision is * and it matches project

		if get_parent().valid_bundleid(_xcode.project.bundle_id, flow.provision) or\
		   flow.provision == null:
			flow.bundle_id = _xcode.project.bundle_id
		else:
			flow.bundle_id = flow.provision.bundle_id

		if flow.provision != null and flow.provision.bundle_id != null:
			# Disable bundle_id editing when provision is not
			# a wild card
			flow.get_section_control(section).set_editable(
				flow.provision.bundle_id.find('*') > -1
			)


func _on_validate(flow, section, input):
	if input == null:
		flow.validate(section, false)
		return
	
	var valid = true
	if section == flow.SECTION.PROVISION:
		# xcode_managed provisions must be automanaged
		flow.automanaged = input.xcode_managed
		flow.get_section_control(flow.SECTION.AUTOMANAGE).set_disabled(input.xcode_managed)
	if section == flow.SECTION.AUTOMANAGE:
		pass
	if section == flow.SECTION.TEAM:
		valid = flow.provision.team_ids.has(input.id)
	if section == flow.SECTION.DISPLAY_NAME:
		pass
	if section == flow.SECTION.BUNDLE_ID:
		valid = input != '*' and get_parent().valid_bundleid(input, flow.provision)
	flow.validate(section, valid)


func _on_onboarded(flow):
	_xcode.project.provision = flow.provision
	_xcode.project.automanaged = flow.automanaged
	_xcode.project.team = flow.team
	_xcode.project.name = flow.display_name
	_xcode.project.bundle_id = flow.bundle_id
	_xcode.project.update()
	
	flow.hide()


