@tool
extends Resource

## Resource used by the J-Custom_Extendsions plugin to map custom resource extensions. [br]
## It is automatically mapped out on engine start and used to track custom resource extensions for the plugin.
## A copy of this resource is saved so that the mapping can be persisted and referenced at runtime.
class_name J_ExtensionMapper

## The map for custom text-based resource extensions (what would be ".tres").
@export var tresMap : Dictionary = {}
## The map for custom binary resource extensions (what would be ".res").
@export var binaryMap : Dictionary = {}

## The constant key used to identify custom text-based resource extensions in a Script. Just add a constant 
## to the Script of a named Class with the name "tresCustom" and assign it the desired extension string, it will 
## automatically be recognized by the extension mapper.
const TRES_CUSTOM = 'tresCustom'
## The constant key used to identify custom binary resource extensions in a Script. Just add a constant 
## to the Script of a named Class with the name "binaryCustom" and assign it the desired extension string, it will 
## automatically be recognized by the extension mapper.
const BINARY_CUSTOM = 'binaryCustom'

## The path where the extension map resource will be saved. This is used to persist the mapping of
## custom extensions so that it can be loaded and referenced at runtime.
const MAP_SAVE_PATH = "res://addons/J-Custom_Extensions/extension_map.tres"

## Builds the extension maps by scanning all globally registered classes for custom extension
## constants and then saves the resulting map resource to the designated path. This ensures
## that the extension mapping is up-to-date and persisted for runtime use.
func build_map():
	tresMap.clear()
	binaryMap.clear()

	var globalClasses : Array[Dictionary] = ProjectSettings.get_global_class_list()

	## Check each globally registered class for custom extension constants and add them to the appropriate map.
	for classInfo in globalClasses:
		var classScript : Script = load(classInfo['path'])
		_try_add_custom_extension_to_map( classScript, TRES_CUSTOM, tresMap )
		_try_add_custom_extension_to_map( classScript, BINARY_CUSTOM, binaryMap )

	var error : int = ResourceSaver.save( self, MAP_SAVE_PATH )
	if error != OK:
		push_error("Failed to save extension map resource at: " + MAP_SAVE_PATH)
	
	elif Engine.is_editor_hint():
		print("--- Registered custom text resource extensions (.tres): \n", tresMap)
		print("--- Registered custom binary resource extensions (.res): \n", binaryMap)


## Attempts to add a custom extension to the provided map by checking if the Script has the specified extension 
## constant and if it is valid. If so, the extension is mapped to the
## Script's global name for later reference.
func _try_add_custom_extension_to_map( classScript : Script, extensionContainer : String, map : Dictionary ) -> void:
	var extension : String = get_classScript_extension(classScript, extensionContainer)
	if extension != "" and not map.has(extension):
		map[extension] = classScript.get_global_name()

## Validates and retrieves the custom extension value from the given Script for the specified extension container. 
## Returns the extension string if valid, otherwise returns an empty string.
func get_classScript_extension( classScript : Script, extensionContainer : String) -> String:
	if classScript != null and extensionContainer in classScript:
		var extension : String = classScript.get(extensionContainer)
		if extension is String and extension != '':
			return extension
	return ""

## Helper function to get all extension recognized by the plugin, combining both TRES and BINARY custom extensions.
func get_recognized_extensions() -> Array:
	var recognized : Array = tresMap.keys()
	recognized += binaryMap.keys()
	return recognized