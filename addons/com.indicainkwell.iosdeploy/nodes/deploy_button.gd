# deploy_button.gd
tool
extends PopupMenu

signal failure(reasons)
signal success()

signal _finished(successful, reasons)



enum DeployOption {
	INSTALL_DEPLOY,
	REMOTE_FS_DEPLOY
}


var deploy_option = INSTALL_DEPLOY


onready var _deploy = get_node('ios_deploy')


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------


func app(app_path, to_device, with_opt=null):
	if with_opt == null:
		with_opt = deploy_option

	if with_opt == INSTALL_DEPLOY:
		_deploy.to(to_device, app_path)
	elif with_opt == REMOTE_FS_DEPLOY:
		_deploy.remote_file_system_to(to_device, app_path, get_local_ip_address())


func get_local_ip_address():
	var cmd = "ipconfig"
	var args = ["getifaddr", "en1"]
	var out = []
	OS.execute(cmd, args, true, out)
	return out[0].strip_edges()


# ------------------------------------------------------------------------------
#                                     Handlers
# ------------------------------------------------------------------------------


func _on_deploy_finished(arr_status):
	print('\n\ndeploy finished callback\n\n', arr_status)
	var errors = []
	for val in arr_status:
		if typeof(val) == TYPE_INT:
			errors.append(val)
	
	emit_signal('_finished', errors.size() == 0, errors)
	
	if errors.size() > 0:
		emit_signal('failure', errors)
	else:
		emit_signal('success')


func _on_about_to_show():
	print('about to show')
	clear()
	for opt in DeployOption.keys():
		add_check_item(opt)
		if DeployOption[opt] == deploy_option:
			set_item_checked(get_item_count() - 1, true)

func _on_item_pressed( ID ):
	deploy_option = DeployOption[get_item_text(ID)]
