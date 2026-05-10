class_name SoundFont
extends Resource
## A set of samples in one audio file.

## The audio file that holds all of the samples.
@export var audio: AudioStream

## Directory of samples, keyed by the sample's ID/name.
@export var samples: Dictionary[StringName, SoundFontSample] = {}


## Play the sample with the given [param id] on [param player] (3D).
## Asynchronous function returns at the end of the sample.
func play_3d(player: AudioStreamPlayer3D, id: StringName):
	if player.stream != audio:
		player.stream = audio

	var sample: SoundFontSample = samples.get(id, null)
	if not sample:
		return

	player.play(sample.start)
	await player.get_tree().create_timer(sample.duration / player.pitch_scale).timeout
	player.stop()


## Load samples from JSON. For development use.
func load_from_json(json: String):
	var parse := JSON.new()
	parse.parse(json)
	load_from_dict(parse.data)


## Load samples from dictionary. For development use.
func load_from_dict(dict: Dictionary):
	for sample_name: String in dict:
		var sample_data: Dictionary = dict[sample_name]
		var sample := SoundFontSample.new()
		sample.start = sample_data["start"]
		sample.duration = sample_data["duration"]
		samples[StringName(sample_name)] = sample
