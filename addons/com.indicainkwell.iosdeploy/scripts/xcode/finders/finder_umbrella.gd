# finder_umbrella.gd
extends Reference


# ------------------------------------------------------------------------------
#                                      Signals
# ------------------------------------------------------------------------------


signal result(this, type, objects)


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const stc = preload('../../static.gd')


enum Type {
	TEAM,
	DEVICE,
	PROVISION
}


# ------------------------------------------------------------------------------
#                                   Dependencies
# ------------------------------------------------------------------------------


var TeamFinder = stc.get_gdscript('xcode/finders/team_finder.gd')
var ProvisionFinder = stc.get_gdscript('xcode/finders/provision_finder.gd')
var DeviceFinder = stc.get_gdscript('xcode/finders/device_finder.gd')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var _team_finder = TeamFinder.new()
var _provision_finder = ProvisionFinder.new()
var _device_finder = DeviceFinder.new()


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _init():
	_team_finder.connect('result', self, '_on_finder_result', [Type.TEAM])
	_device_finder.connect('result', self, '_on_finder_result', [Type.DEVICE])
	_provision_finder.connect('result', self, '_on_finder_result',
			[Type.PROVISION])


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func begin_find_teams():
	_team_finder.begin_find()


func begin_find_provisions():
	_provision_finder.begin_find()


func begin_find_devices():
	_device_finder.begin_find()


# ------------------------------------------------------------------------------
#                                     Handlers
# ------------------------------------------------------------------------------


func _on_finder_result(finder, objects, type):
	emit_signal('result', self, type, objects)
