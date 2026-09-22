extends "res://addons/@fumohouse/navigation/info_screen/info_screen_base.gd"

@onready var _version_label: RichTextLabel = %VersionLabel


func _ready():
	super()

	_version_label.text = (
		"[b]Version:[/b] %s\n[b]Godot version:[/b] %s"
		% [
			DistConfig.get_build_string(),
			BaseUtils.get_engine_version_string(),
		]
	)


func _on_contributor_name_pressed(contributor: MainlineContributor):
	_info_popup.size = Vector2i(500, 300)
	_info_title.text = contributor.name
	_info_body.text = contributor.description
	_info_popup.show()
