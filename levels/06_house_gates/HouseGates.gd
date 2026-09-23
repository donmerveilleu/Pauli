extends Node2D

const PLAYER_SCENE = preload("res://scenes/Player.tscn")
const DIALOGUE_BOX_SCRIPT = preload("res://ui/dialogue/DialogueBox.gd")
const GATE_SCRIPT = preload("res://interactables/gate_puzzle/Gate.gd")


func _ready() -> void:
	LevelUtils.create_floor(self, Vector2(700, 500), Vector2(1600, 50))

	var dialogue = DIALOGUE_BOX_SCRIPT.new()
	add_child(dialogue)

	var player = PLAYER_SCENE.instantiate()
	player.position = Vector2(150, 400)
	add_child(player)

	var gate = GATE_SCRIPT.new()
	gate.position = Vector2(1300, 450)
	add_child(gate)
