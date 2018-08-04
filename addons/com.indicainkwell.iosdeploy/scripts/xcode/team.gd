# team.gd
extends 'Data.gd'


var id
var name
var account
var type
var is_free_account


func to_dict():
	return {
		id = id,
		name = name,
		account = account,
		type = type,
		is_free_account = is_free_account,
	}


func from_dict(d):
	if d == null: return
	id = d['id']
	name = d['name']
	account = d['account']
	type = d['type']
	is_free_account = d['is_free_account']
