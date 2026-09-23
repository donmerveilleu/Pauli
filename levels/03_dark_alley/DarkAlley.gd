extends Node2D

const PLAYER_SCENE = preload("res://scenes/Player.tscn")
const DIALOGUE_BOX_SCRIPT = preload("res://ui/dialogue/DialogueBox.gd")
const STRANGER_SCRIPT = preload("res://characters/npcs/stranger/Stranger.gd")


func _ready() -> void:
	LevelUtils.create_floor(self, Vector2(700, 500), Vector2(1600, 50))

	var dialogue = DIALOGUE_BOX_SCRIPT.new()
	add_child(dialogue)

	var player = PLAYER_SCENE.instantiate()
	player.position = Vector2(150, 400)
	add_child(player)

	var stranger = STRANGER_SCRIPT.new()
	stranger.position = Vector2(700, 450)
	add_child(stranger)

	# Only reachable if the player chose "Ignore" above — a wrong choice
	# routes to the Bad Ending from inside Stranger.gd instead.
	var exit = SceneExit.new()
	exit.position = Vector2(1350, 450)
	exit.next_scene_path = "res://levels/04_dark_alley2/DarkAlley.tscn"
	add_child(exit)
