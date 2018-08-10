# Controller.gd
#
# Base controller class. Using the MVC pattern with the gui as the views is just
# a helper to manage somethings that plugins can't do without user intervention
# e.g. Singletons.
#
# Root of the controller hiearchy must be the EditorPlugin node.
#
# Add register any views or menus with plugin on _ready() or _enter_tree().
#
# Create resources in _enter_tree() callback and cleanup resources in the
# _exit_tree() callback.
#
tool
extends Node


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const stc = preload('../static.gd')
var Controller = stc.get_gdscript('controllers/Controller.gd')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var __plugin = null # use get_plugin() in subclasses


# ------------------------------------------------------------------------------
#                                      SetGets
# ------------------------------------------------------------------------------


var view setget ,get_view
func get_view():
	"""
	Get the view that this controller manages.
	"""
	return view




# ------------------------------------------------------------------------------
#                                  Node Overrides
# ------------------------------------------------------------------------------


func _enter_tree():
	assert(
		stc.isa(get_parent(), EditorPlugin)
		or
		stc.isa(get_parent(), Controller)
	)


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func get_plugin():
	"""
	Get the plugin node i.e. ios_deploy_main.gd. Must be inside tree. The
	root of the control hieararchy must be ios_deploy_main.gd. Caches plugin
	node.
	"""
	if __plugin == null:
		var parent = get_parent()
		if stc.isa(parent, Controller):
			__plugin = parent.get_plugin()
		elif stc.isa(parent, EditorPlugin):
			__plugin = parent
	return __plugin
