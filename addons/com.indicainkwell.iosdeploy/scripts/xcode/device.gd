# device.gd
extends 'Data.gd'


enum Type {
	Unknown,
	iPhone,
	iPad,
	Simulator,
	Mac
}


enum Connection {
	USB,
	WIFI
}


var id
var name
var type_info
var type = Type.Unknown
var connection = Connection.USB


func to_dict():
	return {
		id = id,
		name = name,
		type_info = type_info,
		type = type,
		connection = connection,
	}


func from_dict(d):
	if d == null: return
	id = d['id']
	name = d['name']
	type_info = d['type_info']
	type = d['type']
	connection = d['connection']
