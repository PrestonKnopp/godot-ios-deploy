# finder.gd
extends Reference


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const stc = preload('../../static.gd')


# ------------------------------------------------------------------------------
#                                     Subtypes
# ------------------------------------------------------------------------------


var Json = stc.get_gdscript('json.gd')


# ------------------------------------------------------------------------------
#                              Static Factory Methods
# ------------------------------------------------------------------------------


static func find_teams():
	return stc.get_gdscript('xcode/finders/team_finder.gd').new().find()


static func find_provisions():
	return stc.get_gdscript('xcode/finders/provision_finder.gd').new().find()


static func find_devices():
	return stc.get_gdscript('xcode/finders/device_finder.gd').new().find()


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var _log = stc.get_logger().make_module_logger(stc.PLUGIN_DOMAIN + '.finder')
var _shell = stc.get_gdscript('shell.gd').new()
var _sh = _shell.make_command('/bin/bash')
var _json = Json.new()


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


# func _init():
# 	pass


# ------------------------------------------------------------------------------
#                                 Abstract Methods
# ------------------------------------------------------------------------------


func find():
	assert('Call factory methods'.empty())
