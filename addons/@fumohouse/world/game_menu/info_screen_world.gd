extends "res://addons/@fumohouse/navigation/info_screen/info_screen_base.gd"

@onready var _info_tab: Control = $Contents/MarginContainer/TabContent/Info


func _ready():
	var world: WorldManifest = WorldManager.get_singleton().current_world
	if world:
		entry_module = world.name

		if world.info_scene.is_empty():
			var placeholder_label := RichTextLabel.new()
			placeholder_label.bbcode_enabled = true
			placeholder_label.fit_content = true
			placeholder_label.scroll_active = false
			placeholder_label.text = "[b]%s[/b] by %s" % [world.display_name, world.author]
			placeholder_label.set_anchors_preset(Control.PRESET_FULL_RECT)

			_info_tab.add_child(placeholder_label)
		else:
			var scene = load(world.info_scene) as PackedScene
			if not scene:
				push_error("Failed to load info scene: %s" % world.info_scene)
				return

			_info_tab.add_child(scene.instantiate())

	super()
