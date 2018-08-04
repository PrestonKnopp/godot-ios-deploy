# provision.gd
extends 'Data.gd'


var id
var name
var app_id # entitled bundleid prefixed with teamid
var app_id_name
var bundle_id
#var entitlements
var platforms
var team_ids
var team_name
var creation_date
var expiration_date


func to_dict():
	return {
		id = id,
		name = name,
		app_id = app_id,
		app_id_name = app_id_name,
		bundle_id = bundle_id,
		platforms = platforms,
		team_ids = team_ids,
		team_name = team_name,
		creation_date = creation_date,
		expiration_date = expiration_date,
	}


func from_dict(d):
	if d == null: return
	id = d['id']
	name = d['name']
	app_id = d['app_id']
	app_id_name = d['app_id_name']
	bundle_id = d['bundle_id']
	platforms = d['platforms']
	team_ids = d['team_ids']
	team_name = d['team_name']
	creation_date = d['creation_date']
	expiration_date = d['expiration_date']


