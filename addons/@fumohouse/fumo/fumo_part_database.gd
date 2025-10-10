class_name FumoPartDatabase
extends PartDatabase
## Database for fumo parts.


static func get_singleton() -> FumoPartDatabase:
	return Modules.get_singleton(&"FumoPartDatabase") as FumoPartDatabase


func _ready():
	scan_dir("res://addons/@fumohouse/fumo_models/resources/part_data")
