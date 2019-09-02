# deploy.gd
#
# Interface to user configured deploy tool. Uses a tool strategy to interact
# with lower level tool api.
#
# By default, subscribes to deploy tool config changes. Turn off automatic
# subscription by passing false in to the constructor.
extends Reference


# ------------------------------------------------------------------------------
#                                      Signals
# ------------------------------------------------------------------------------


signal task_started(task, message)
signal task_progressed(task, message, step_current, step_total)
signal task_finished(task, message, error, result)


# ------------------------------------------------------------------------------
#                                     Constants
# ------------------------------------------------------------------------------


const stc = preload('../../static.gd')
const DEPLOY_CONFIG_SECTION = 'deploy'
const DEPLOY_TOOL_CONFIG_KEY = 'tool'


# ------------------------------------------------------------------------------
#                                   Dependencies
# ------------------------------------------------------------------------------


var ToolStrategy = stc.get_gdscript('xcode/deploy/ToolStrategy.gd')
var IOSDeployToolStrategy = stc.get_gdscript('xcode/deploy/ios_deploy_tool_strategy.gd')
var LibimobiledeviceToolStrategy = stc.get_gdscript('xcode/deploy/libimobiledevice_tool_strategy.gd')


# ------------------------------------------------------------------------------
#                                     Variables
# ------------------------------------------------------------------------------


var _tool_strategy = ToolStrategy.new()
var _supported_strategies = [
	IOSDeployToolStrategy,
	LibimobiledeviceToolStrategy
]


# ------------------------------------------------------------------------------
#                                     Overrides
# ------------------------------------------------------------------------------


func _init(subscribes_to_tool_changes=true, use_config_tool_name=true):
	if use_config_tool_name:
		var cfg = stc.get_config()
		var deploy_tool_name = cfg.get_value(
			DEPLOY_CONFIG_SECTION,
			DEPLOY_TOOL_CONFIG_KEY
		)
		if deploy_tool_name == null:
			var avail = get_available_strategies()
			if avail.size() > 0:
				_use_tool_strategy_by_name(avail[0].get_tool_name())
		else:
			_use_tool_strategy_by_name(deploy_tool_name, cfg)
	if subscribes_to_tool_changes:
		var cfg = stc.get_config()
		cfg.connect("changed", self, "_on_config_changed")


func get_supported_strategies():
	return _supported_strategies


func get_available_strategies():
	var avail = []
	for strat_type in get_supported_strategies():
		var strat = strat_type.new()
		if strat.tool_available():
			avail.append(strat)
	return avail


func _use_tool_strategy_by_name(name, with_config):
	_tool_strategy = null
	for strat in get_available_strategies():
		if name == strat.get_tool_name():
			_tool_strategy = strat
			break
	if _tool_strategy == null:
		_tool_strategy = ToolStrategy.new()
	if with_config != null:
		for key in _tool_strategy.get_config_keys():
			var value = with_config.get_value(
				_tool_strategy.get_config_section(),
				key
			)
			_tool_strategy.handle_config_key_change(key, value)
	stc.forward_signals(['task_started', 'task_progressed',
		'task_finished'], _tool_strategy, self)


# ------------------------------------------------------------------------------
#                                      Methods
# ------------------------------------------------------------------------------



func get_available_tasks():
	return _tool_strategy.get_available_tasks()


func start_task(task, arguments):
	_tool_strategy.start_task(task, arguments)


# ------------------------------------------------------------------------------
#                                     Handlers
# ------------------------------------------------------------------------------


func _on_config_changed(config, section, key, from_value, to_value):
	if section == DEPLOY_CONFIG_SECTION and key == DEPLOY_TOOL_CONFIG_KEY:
		_use_tool_strategy_by_name(to_value, config)
	
	if section == _tool_strategy.get_config_section() and\
	   key in _tool_strategy.get_config_keys():
		   _tool_strategy.handle_config_key_change(key, to_value)
