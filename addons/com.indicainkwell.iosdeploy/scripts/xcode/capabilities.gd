# capabilities.gd
#
# Encapsulates "System Capabilities" or "App Capabilities". These include
# GameCenter, Push, and InAppPurchase capabilities.
extends Reference

const Capability = {
	GAME_CENTER = 'com.apple.GameCenter',
	IN_APP_PURCHASE = 'com.apple.InAppPurchase',
	PUSH = 'com.apple.Push'
}

var _dict = {}

func _init():
	# enable all by default
	for capability in Capability.values():
		enable(capability)

func enable(capability):
	if not capability in _dict:
		_dict[capability] = {
			# Enabled is a string in the pbxproj
			enabled = '1'
		}

func disable(capability):
	if capability in _dict:
		_dict.erase(capability)

func to_dict():
	var copy = {}
	for k in _dict:
		copy[k] = _dict[k]
	return copy
