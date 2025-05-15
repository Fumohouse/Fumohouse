extends Control

const POINTS := 25

const FREQ_LOW := 10
const FREQ_HIGH := 15000

const RANGE_LEN := (FREQ_HIGH - FREQ_LOW) / float(POINTS)

const MIN_DB := -70.0
const MAX_DB := 50.0

var _curve: Curve2D
var _spectrum: AudioEffectSpectrumAnalyzerInstance
var _histogram: PackedFloat32Array = []

@onready var _mp := MusicPlayer.get_singleton()


func _ready():
	_curve = Curve2D.new()

	var bus := AudioServer.get_bus_index(MusicPlayer.BUS)
	assert(bus >= 0, "Music audio bus not found")
	_spectrum = AudioServer.get_bus_effect_instance(bus, 0)

	_histogram.resize(POINTS)


func _draw():
	_curve.clear_points()

	var ctl_offset := Vector2(5, 0)

	for i in range(POINTS):
		var vertex := _get_point(i)
		_curve.add_point(vertex, -ctl_offset, ctl_offset)

	var points: PackedVector2Array = _curve.tessellate()
	points.push_back(Vector2(self.size.x, self.size.y))
	points.push_back(Vector2(0, self.size.y))

	draw_colored_polygon(points, Color.WHITE)


func _process(_delta: float):
	for i in range(POINTS):
		var factor := 0.0

		if _mp.playing:
			var freq_low := FREQ_LOW + RANGE_LEN * i
			var freq_high := freq_low + RANGE_LEN

			var magnitude := _spectrum \
					.get_magnitude_for_frequency_range(freq_low, freq_high) \
					.length()

			factor = clampf(
					(linear_to_db(magnitude) - MIN_DB) / (MAX_DB - MIN_DB),
					0,
					1
			)

		var smoothing_factor := 0.1 if factor == 0 else 0.7
		_histogram[i] = factor * smoothing_factor \
				+ _histogram[i] * (1 - smoothing_factor)

	queue_redraw()


func _get_point(i: int) -> Vector2:
	var factor := maxf(_histogram[i], 0.01)
	return Vector2(
			i / float(POINTS) * self.size.x,
			self.size.y - factor * self.size.y
	)
