extends Node

const stc = preload('res://addons/com.indicainkwell.iosdeploy/scripts/static.gd')
const Shell = preload('res://addons/com.indicainkwell.iosdeploy/scripts/shell.gd')
const Xcode = preload('res://addons/com.indicainkwell.iosdeploy/scripts/xcode.gd')

func _ready():
	var xcode = Xcode.new()
	
	print('--------------------------------------------------')
	
	print(stc.get_ios_export_template_path())
	
	print('--------------------------------------------------')
	
	print(stc.get_version().get_string())
	
	print('--------------------------------------------------')

	for team in xcode.get_teams():
		print('Team %s: %s for %s' % [team.name, team.id, team.account])
	
	print('--------------------------------------------------')
	
	for prov in xcode.get_provisions():
		print('Provision %s: %s' % [prov.name, prov.id])

	print('--------------------------------------------------')
	
	for device in xcode.get_devices():
		print('Device<type %s> "%s": "%s"' % [str(device.type), device.name, device.id])

	print('--------------------------------------------------')
