extends Control

signal edit_pressed

const CharacterViewport := preload(
	"res://addons/@fumohouse/fumo/character_editor/components/character_viewport.gd"
)
const MenuUtils := preload("../menu_utils.gd")

var _tween: Tween

@onready var _fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()

@onready var _character_viewport: CharacterViewport = %CharacterViewport
@onready var _edit_button: Button = %EditButton


func _ready():
	_edit_button.pressed.connect(edit_pressed.emit)

	_load_appearance()
	_fumo_appearances.active_changed.connect(_load_appearance)


func nav_hide():
	scale = Vector2(0, 1)
	modulate = Color.TRANSPARENT


func nav_show():
	scale = Vector2.ONE
	modulate = Color.WHITE


func nav_transition(vis: bool):
	if _tween:
		_tween.kill()

	visible = true

	var tween := MenuUtils.common_tween(self, vis)

	tween.tween_property(
		self, "scale", Vector2.ONE if vis else Vector2(0, 1), MenuUtils.TRANSITION_DURATION
	)
	tween.parallel().tween_property(
		self, "modulate", Color.WHITE if vis else Color.TRANSPARENT, MenuUtils.TRANSITION_DURATION
	)

	_tween = tween

	if not vis:
		await tween.finished
		visible = false


func _load_appearance():
	_character_viewport.character.appearance_manager.appearance = _fumo_appearances.active
	_character_viewport.character.appearance_manager.load_appearance()
