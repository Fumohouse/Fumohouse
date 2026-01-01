class_name MainlineContributorDatabase
extends Node

var _contributors: Array[MainlineContributor] = []


static func get_singleton() -> MainlineContributorDatabase:
	return Modules.get_singleton(&"MainlineContributorDatabase") as MainlineContributorDatabase


func _ready():
	_scan_dir("res://addons/@fumohouse/mainline_contrib/resources")


func get_contributors(category: StringName) -> Array[MainlineContributor]:
	var weight_list: Array[MainlineContributor] = []
	var alphabet_list: Array[MainlineContributor] = []

	for contrib in _contributors:
		if contrib.category != category:
			continue

		if contrib.weight >= 0:
			weight_list.push_back(contrib)
		else:
			alphabet_list.push_back(contrib)

	weight_list.sort_custom(
		func(a: MainlineContributor, b: MainlineContributor): return a.weight < b.weight
	)

	alphabet_list.sort_custom(
		func(a: MainlineContributor, b: MainlineContributor):
			return a.name.naturalnocasecmp_to(b.name) < 0
	)

	return weight_list + alphabet_list


func _scan_dir(path: String):
	var contents: PackedStringArray = ResourceLoader.list_directory(path)

	for file_name in contents:
		if file_name.ends_with("/"):
			# Directory
			_scan_dir("%s/%s/" % [path, file_name])
		elif file_name.ends_with(".tres"):
			var contributor = load(path + "/" + file_name)

			if contributor is MainlineContributor:
				_contributors.push_back(contributor)
