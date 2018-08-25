# error.gd
#
# A aggregate class of possible error schemes.
extends Reference

var category
var code
var message

func to_string():
	return 'Error(Code:%s, Category:%s, Message:%s)' % [code, category, message]
