extends PointLight2D

var intervals = [0.2, 0.1, 0.3, 0.2]
var interval_index = 0
var timer = 0.0


func _ready() -> void:
	energy = 0.0


func _process(delta: float) -> void:
	timer += delta

	if timer >= intervals[interval_index]:
		timer = 0.0

		flickering_light()

		interval_index += 1

		if interval_index >= intervals.size():
			interval_index = 0


func flickering_light() -> void:
	if energy == 0.0:
		energy = 1.0
	else:
		energy = 0.0
