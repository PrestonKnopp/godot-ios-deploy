# deploy.gd
extends Reference


signal detected_devices(this, devices)
signal deployed(this, to_device)
signal deployment_failure(this, device)
signal deployment_finished(this, result)


const stc = preload('static.gd')


class Device:
	enum Type {
		Unknown,
		iPhone,
		iPad,
		Simulator,
		Mac
	}

	var id
	var name
	var type


func list_devices():

	var listknowndevices = stc.get_shell_script(stc.shell.listknowndevices)
	var res = _sh.run(listknowndevices)
	if res.code != 0:
		return []

	var devices = []

	# for some reason multiline output is all in first element
	for line in res.output[0].split('\n', false):
		# skip sims until add support for x86 project gen
		if line.find('] (Simulator)') != -1:
			continue

		var device = Device.new()
		var end_name_idx = line.rfind('[')
		device.name = line.substr(0, end_name_idx).strip_edges()


		var end_id_idx = line.find(']', end_name_idx)

		# move passed '['
		end_name_idx += 1

		var id_length = end_id_idx - end_name_idx
		device.id = line.substr(end_name_idx, id_length)

		device.type = device.Type.Unknown
		if device.name.findn('macbook') != -1:
			device.type = device.Type.Mac
		elif device.name.findn('iphone') != -1:
			device.type = device.Type.iPhone
		elif device.name.findn('ipad') != -1:
			device.type = device.Type.iPad

		devices.append(device)
	return devices


# Devices to deploy to
var devices = []


# TODO: test if ios-deploy can be run in parallel
# Deploy to each device in parallel
func deploy(app_path): pass
# Async detect connected devices
func detect(): pass