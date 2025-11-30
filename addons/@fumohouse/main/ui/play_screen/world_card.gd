extends PanelContainer

## The world to display, loaded on ready.
var world: WorldManifest


func _ready():
	if not world:
		return

	%Name.text = world.display_name
	%Version.text = "v" + world.version
	%Description.text = world.description

	%SingleplayerButton.pressed.connect(
		func(): WorldManager.get_singleton().start_singleplayer(world.name)
	)
