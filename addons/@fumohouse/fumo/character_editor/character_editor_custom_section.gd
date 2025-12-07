class_name CharacterEditorCustomSection
extends MarginContainer

@onready var _grid: GridContainer = %Grid

@onready var _title: Label = %Title

@export var scope: String


func _ready():
	_title.text = scope


func add_item(part: PartData):
	var button := Button.new()
	button.text = part.display_name
	_grid.add_child(button)
