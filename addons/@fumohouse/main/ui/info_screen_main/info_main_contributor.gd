extends Control

signal name_pressed

@export var contributor: MainlineContributor

@onready var _name: LinkButton = %Name
@onready var _role: Label = %Role


func _ready():
	_name.text = contributor.name
	_name.pressed.connect(name_pressed.emit)
	_role.text = contributor.role
