extends SubViewport


@onready var _character_manager: CharacterManager = %CharacterManager

@onready var fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()


func _ready() -> void:
	_character_manager.debug_character = DebugCharacter.new()
	_character_manager._spawn_character(fumo_appearances._staging)
