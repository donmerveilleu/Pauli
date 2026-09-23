extends Node2D

const PLAYER_SCENE = preload("res://scenes/Player.tscn")
const DIALOGUE_BOX_SCRIPT = preload("res://ui/dialogue/DialogueBox.gd")
const HABAL_DRIVER_SCRIPT = preload("res://characters/npcs/habal_driver/HabalDriver.gd")


func _ready() -> void:
	LevelUtils.create_floor(self, Vector2(700, 500), Vector2(1600, 50))

	var dialogue = DIALOGUE_BOX_SCRIPT.new()
	add_child(dialogue)

	var player = PLAYER_SCENE.instantiate()
	player.position = Vector2(150, 400)
	add_child(player)

	var driver = HABAL_DRIVER_SCRIPT.new()
	driver.position = Vector2(600, 450)
	add_child(driver)

	var exit = SceneExit.new()
	exit.position = Vector2(1350, 450)
	exit.next_scene_path = "res://levels/03_dark_alley/DarkAlley.tscn"
	add_child(exit)
