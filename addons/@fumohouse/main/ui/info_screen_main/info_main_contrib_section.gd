extends Control

signal name_pressed(contrib: MainlineContributor)

const InfoMainContributor := preload("info_main_contributor.gd")
const _CONTRIB_SCENE := preload("info_main_contributor.tscn")

@export var category := &""

@onready var _contrib_flow: Control = %ContributorFlow


func _ready():
	for contrib in MainlineContributorDatabase.get_singleton().get_contributors(category):
		var contrib_node: InfoMainContributor = _CONTRIB_SCENE.instantiate()
		contrib_node.contributor = contrib
		contrib_node.name_pressed.connect(name_pressed.emit.bind(contrib))
		_contrib_flow.add_child(contrib_node)
