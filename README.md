# J-Custom_Extensions

A Godot plugin that simplifies the process of creating custom resource file types in Godot. Instead of relying on standard `.tres` (text) or `.res` (binary) formats, you can define your own custom extensions and associate them with your resource classes.


## Installation

1. Copy the `addons` folder into your project.
2. In the Godot editor, go to **Project → Project Settings → Plugins** and enable **J-Custom_Extensions**.


### Defining Custom Extensions

To register a custom extension for a resource class, add a constant to your class definition:

#### Minimal Example

```gdscript
extends Resource
class_name MyCustomResource

const tresCustom = "mcr"  # Custom alternative "tres" extension
const binaryCustom = "mcrb"  # Custom alternative "res" extension

@export var data: String = "example"
@export var value: int = 0
```

**Notes:**
- Do not include the dot when defining `tresCustom` or `binaryCustom`.
- Any `Resources` that are extensions of ones with defined custom extensions will also inherit them.
- Custom extensions do work in exported projects.

### Refreshing Extensions

If you add or modify custom extensions in your classes they will need to be refreshed, this is done automatically when the engine is restarted but can also be done manually:
1. Go to **Tools → Refresh Custom Extensions** in the Godot editor
2. Or call `build_map()` on the extension mapper at runtime

## How It Works

### Architecture

The plugin consists of three main components:

1. **main.gd** - The plugin entry point that manages the editor integration
2. **extension_mapper.gd** - Scans project classes and maintains extension mappings
3. **save_loader.gd** - Implements custom ResourceFormatLoader and ResourceFormatSaver

## Requirements

- Godot 4.0+
- Custom resource classes must be globally registered (using `class_name`)

## License

See [LICENSE](LICENSE)

## Support & Troubleshooting

### Extensions Not Loading

- Ensure your class has `class_name` defined
- Verify the constant name is exactly `tresCustom` or `binaryCustom`
- Try refreshing extensions via **Tools → Refresh Custom Extensions**

### Custom Loader/Saver Not Recognized

- Check that the extension mapping file exists at `res://addons/J-Custom_Extensions/extension_map.tres`
- Restart the editor or refresh custom extensions via **Tools → Refresh Custom Extensions** if the file is corrupted

### Runtime vs Editor Differences

- In the editor, the plugin dynamically manages the loader/saver
- At runtime, an autoloaded instance handles all custom extension operations
- Extension mappings are persistent and loaded automatically
