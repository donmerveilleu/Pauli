extends Node2D

var bulbs = [
	preload("res://MainMenuAssets/dimLight.png"),
	preload("res://MainMenuAssets/onLight.png"),
	preload("res://MainMenuAssets/bulb.png")
]

var current_bulb = 0
var timer = 0.0

@onready var bulb = $Bulb


func _ready() -> void:
	bulb.texture = bulbs[current_bulb]


func _process(delta: float) -> void:
	timer += delta

	if timer >= 0.1:
		timer = 0.0

		flickering_light()


func flickering_light() -> void:
	current_bulb += 1

	if current_bulb >= bulbs.size():
		current_bulb = 0

	bulb.texture = bulbs[current_bulb]


func display_menu() -> void:
	pass





func _on_audio_stream_player_2d_finished() -> void:
	pass


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
	


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("")
	



func _on_quit_pressed() -> void:
	get_tree().quit()
