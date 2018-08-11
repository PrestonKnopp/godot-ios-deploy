# onboarding_flow_controller.gd
#
# Responds to input received from gui/onboarding_flow.gd and updates
# controller.gd accordingly.
#
# Implements onboarding validation logic.
#
# TODO: get rid of get_parent() calls
tool
extends 'Controller.gd'

var OnboardingFlowScene = stc.get_scene('onboarding_flow.tscn')

var _xcode
var _xcode_project

func set_xcode_project(project):
	_xcode_project = project

func set_xcode(xcode):
	_xcode = xcode

func _enter_tree():
	view = OnboardingFlowScene.instance()
	view.connect('onboarded', self, '_on_onboarded')
	view.connect('populate', self, '_on_populate')
	view.connect('validate', self, '_on_validate')
	get_plugin().add_menu(view)

func _exit_tree():
	view.queue_free()

func _on_populate(flow, section):
	if section == flow.SECTION.PROVISION:
		var provisions = get_parent().filter_provisions(_xcode.finder.find_provisions())
		flow.populate_option_section(section, provisions)
		if _xcode_project.provision != null:
			flow.provision = _xcode_project.provision
		elif provisions.size() > 0:
			flow.provision = provisions.front()
	
	if section == flow.SECTION.AUTOMANAGE:
		flow.automanaged = _xcode_project.automanaged
	
	if section == flow.SECTION.TEAM:
		var teams = _xcode.finder.find_teams()
		var team = null

		if _xcode_project.team != null:
			team = _xcode_project.team
			# Add xcode project's current team to teams. This may
			# happen when find_teams doesn't find any teams, but
			# xcode_project has been loaded from saved config.
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

		flow.populate_option_section(section, teams)
		flow.team = team
	
	if section == flow.SECTION.DISPLAY_NAME:
		if _xcode_project.name != null:
			flow.display_name = _xcode_project.name
	
	if section == flow.SECTION.BUNDLE_ID:
		if _xcode_project.bundle_id != null:
			flow.bundle_id = _xcode_project.bundle_id
		else:
			flow.bundle_id = flow.provision.bundle_id


func _on_validate(flow, section, input):
	var valid = true
	if section == flow.SECTION.PROVISION:
		pass
	if section == flow.SECTION.AUTOMANAGE:
		pass
	if section == flow.SECTION.TEAM:
		valid = flow.provision.team_ids.has(input.id)
	if section == flow.SECTION.DISPLAY_NAME:
		pass
	if section == flow.SECTION.BUNDLE_ID:
		valid = get_parent().valid_bundleid(input, flow.provision)
	flow.validate(section, valid)


func _on_onboarded(flow):
	_xcode_project.provision = flow.provision
	_xcode_project.automanaged = flow.automanaged
	_xcode_project.team = flow.team
	_xcode_project.name = flow.display_name
	_xcode_project.bundle_id = flow.bundle_id
	_xcode_project.update()
	
	flow.hide()


