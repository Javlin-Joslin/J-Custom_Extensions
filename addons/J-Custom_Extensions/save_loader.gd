@tool
extends Node
#This is the node responsible for setting up and managing the custom resource loader and saver for the J-Extension_Mapper plugin.

## Reference to the resource that holds the mapping information for the custom loader and saver.
var mapResource : J_ExtensionMapper 
## Reference to the custom resource loader used by this node.
var _loader : custom_loader
## Reference to the custom resource saver used by this node.
var _saver  : custom_saver


#region Setup
# When at runtime the extension list should never need to be refreshed so the save_loader created by the autoload can just do
# its thing by itself. In editor however the plugin script needs to take over and manage the setup and teardown of a
# save_loader node so that it can be refreshed without needing to completely restart the editor, thus we have the autoloaded 
# save_loader do nothing so they don't conflict.
func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	setup()

## Loads the map Resource and sets up the resource loader and saver by initializing them and registering them with the engine.
func setup() -> void:
	mapResource = load( J_ExtensionMapper.MAP_SAVE_PATH )

	_loader = custom_loader.new()
	_loader.mapResource = mapResource
	_saver = custom_saver.new()
	_saver.mapResource = mapResource

	ResourceLoader.add_resource_format_loader( _loader )
	ResourceSaver.add_resource_format_saver( _saver )

## Shorthand method to trigger the method of the same name in the J_ExtensionMapper resource used by this node, causing it
## to rebuild its internal mapping of recognized extensions.
func build_map() -> void:
	mapResource.build_map()

#endregion


#region Custom Loader
## Custom ResourceFormatLoader used by this node to handle loading resources with custom extensions.
class custom_loader:
	extends ResourceFormatLoader
	var mapResource : J_ExtensionMapper

	func _get_recognized_extensions() -> PackedStringArray:
		return mapResource.get_recognized_extensions()
	
	func _recognize_path( path : String, type : StringName ) -> bool:
		var pathExtension : String = path.get_extension().to_lower()
		return mapResource.tresMap.has(pathExtension) or mapResource.binaryMap.has(pathExtension)
	
	func _get_resource_type( path : String ) -> String:
		if _get_resource_script_class(path) != '':
			return "Resource"
		return ''
	
	func _get_resource_script_class(path: String) -> String:
		var pathExtension : String = path.get_extension().to_lower()
		if mapResource.tresMap.has(pathExtension):
			return mapResource.tresMap[pathExtension]
		
		if mapResource.binaryMap.has(pathExtension):
			return mapResource.binaryMap[pathExtension]
		
		return ''

	func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int) -> Variant:
		var extension : String = path.get_extension().to_lower()
		
		if not FileAccess.file_exists(path):
			return ERR_FILE_NOT_FOUND

		# If the file extension corresponds to a binary-mapped custom extension, we can just load it directly
		# without any conversion
		if mapResource.binaryMap.has(extension):
			var file : FileAccess = FileAccess.open(path, FileAccess.READ)
			if not file:
				return ERR_CANT_OPEN
			
			var loaded = file.get_var( true )
			file.close()
			if loaded is Resource:
				return loaded
			return FAILED
		
		# If the file extension corresponds to a TRES-mapped custom extension, we need to read the file as text
		# and convert it into a Resource using str_to_var.
		elif mapResource.tresMap.has(extension):
			var file : FileAccess = FileAccess.open(path, FileAccess.READ)
			if not file:
				return ERR_CANT_OPEN
			
			var dataString = file.get_as_text()
			file.close()

			var loaded = str_to_var(dataString)
			if loaded is Resource:
				return loaded
			return FAILED
			
		return FAILED
	

#endregion


#region Custom Saver
## Custom ResourceFormatSaver used by this node for saving resources with custom extensions.
class custom_saver:
	extends ResourceFormatSaver
	var mapResource : J_ExtensionMapper

	func _recognize( resource : Resource ) -> bool:
		var classScript : Script = resource.get_script()
		if classScript == null:
			return false
		
		return not _get_resource_extensions(classScript).is_empty()

	func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
		var classScript : Script = resource.get_script()
		if classScript == null:
			return []
		
		return _get_resource_extensions(classScript)
	
	## Steps up through the inheritance chain of the given Script, collecting the recognized custom extensions 
	## for the resource class represented by the Script and returning them. Used by the saver's custom
	## "_recognize" and "_get_recognized_extensions" methods.
	func _get_resource_extensions( currentScript : Script ) -> PackedStringArray:
		var extensions : PackedStringArray = []

		var seenText : bool = false
		var seenBinary : bool = false

		while currentScript != null:
			var className : String = currentScript.get_global_name()

			if not seenText:
				var textExtension : String =  mapResource.get_classScript_extension(currentScript, mapResource.TRES_CUSTOM)
				if textExtension != '':
					extensions.append(textExtension)
					seenText = true
					if seenBinary:
						break
			
			if not seenBinary:
				var binaryExtension : String =  mapResource.get_classScript_extension(currentScript, mapResource.BINARY_CUSTOM)
				if binaryExtension != '':
					extensions.append(binaryExtension)
					seenBinary = true
					if seenText:
						break
			
			currentScript = currentScript.get_base_script()
				

		return extensions

	func _recognize_path( resource : Resource, path : String ) -> bool:
		var extension : String = path.get_extension().to_lower()
		return mapResource.tresMap.has(extension) or mapResource.binaryMap.has(extension)

	func _save( resource : Resource, path : String, flags : int) -> int:
		var extension : String = path.get_extension().to_lower()

		## if the intended file extension is for binary resources we write the resource directly with 
		## FileAccess.store_var without any conversions.
		if mapResource.binaryMap.has(extension):
			var file = FileAccess.open(path, FileAccess.WRITE)
			if not file:
				return FAILED
			
			file.store_var(resource, true)
			file.close()
			return OK
		
		## if the intended file extension is for text-based resources we convert the resource data to
		## a string representation and write it to the file.
		elif mapResource.tresMap.has(extension):
			var file = FileAccess.open(path, FileAccess.WRITE)
			if not file:
				return FAILED
				
			var dataString : String = var_to_str(resource)
			
			file.store_string(dataString)
			file.close()
			return OK


		return FAILED
