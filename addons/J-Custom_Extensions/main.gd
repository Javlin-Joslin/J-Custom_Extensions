@tool
extends EditorPlugin

const PROJECT_SETTING : String = 'autoload/custom_save_loader'
const SAVE_LOADER_PATH : String = 'res://addons/J-Custom_Extensions/save_loader.gd'
var _save_loader : Node

func _enter_tree():
	if load( J_ExtensionMapper.MAP_SAVE_PATH ) == null:
		ResourceSaver.save( J_ExtensionMapper.new(), J_ExtensionMapper.MAP_SAVE_PATH )
	
	_setup()

	add_tool_menu_item('Refresh Custom Extensions', _refresh)
	ProjectSettings.set_setting(PROJECT_SETTING, '*' + SAVE_LOADER_PATH)
	ProjectSettings.save()

func _setup():
	_save_loader = load(SAVE_LOADER_PATH).new()
	add_child(_save_loader)
	_save_loader.setup()
	_save_loader.build_map()

func _refresh():
	_save_loader.queue_free()
	_setup()
	

func _exit_tree():
	remove_tool_menu_item('Refresh Custom Extensions')
	_save_loader.cleanup()
	ProjectSettings.set_setting(PROJECT_SETTING, null)
	ProjectSettings.save()

