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
#                                      Scenes
# ------------------------------------------------------------------------------


var OnboardingFlowScene = stc.get_scene('onboarding_flow.tscn')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var _xcode


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


func _make_automanaged_provision_representation():
	var provision = _xcode.Provision.new()
	provision.name = 'Automanaged'
	provision.bundle_id = '*'
	provision.xcode_managed = true
	provision.team_ids = []

	for team in _xcode.finder.find_teams():
		provision.team_ids.append(team.id)
	
	return provision


# ------------------------------------------------------------------------------
#                             Onboarding Flow Callbacks
# ------------------------------------------------------------------------------


func _on_populate(flow, section):
	if section == flow.SECTION.PROVISION:
		var provisions = [_make_automanaged_provision_representation()] +\
			get_parent().filter_provisions(_xcode.finder.find_provisions())

		flow.populate_option_section(section, provisions)
		if _xcode.project.provision != null:
			flow.provision = _xcode.project.provision
		elif provisions.size() > 0:
			flow.provision = provisions.front()
	
	if section == flow.SECTION.AUTOMANAGE:
		flow.automanaged = _xcode.project.automanaged
	
	if section == flow.SECTION.TEAM:
		var teams = _xcode.finder.find_teams()
		var team = null

		if _xcode.project.team != null:
			team = _xcode.project.team
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


