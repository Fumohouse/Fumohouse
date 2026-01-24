class_name AudioConfigManager
extends Node
## Autoload for adding audio options to [ConfigManager].

const LOG_SCOPE := "Config:Audio"


func _enter_tree():
	var cm := ConfigManager.get_singleton()

	cm.add_opt(
		&"audio/output_device",
		"Default",
		func(value: String):
			var devices: PackedStringArray = AudioServer.get_output_device_list()
			if devices.has(value):
				AudioServer.output_device = value
			else:
				Log.warn(
					(
						"Requested audio output device '%s' not found. Falling back to default."
						% value
					),
					LOG_SCOPE
				)
				AudioServer.output_device = "Default"
	)

	add_audio_bus(&"Master")
	add_audio_bus(&"Music")


func add_audio_bus(bus: StringName):
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		Log.error("Could not find audio bus '%s'." % bus, LOG_SCOPE)
		return

	ConfigManager.get_singleton().add_opt(
		"audio/bus/%s/volume" % bus,
		80.0,
		func(value: float): AudioServer.set_bus_volume_db(idx, linear_to_db(value / 100.0))
	)
