extends Node2D

const PLAYER_SCENE = preload("res://scenes/Player.tscn")
const DIALOGUE_BOX_SCRIPT = preload("res://ui/dialogue/DialogueBox.gd")
const TINDERA_SCRIPT = preload("res://characters/npcs/tindera/Tindera.gd")
const TAMBAY_SCRIPT = preload("res://characters/npcs/tambay/Tambay.gd")


func _ready() -> void:
	LevelUtils.create_floor(self, Vector2(700, 500), Vector2(1600, 50))

	var dialogue = DIALOGUE_BOX_SCRIPT.new()
	add_child(dialogue)

	var player = PLAYER_SCENE.instantiate()
	player.position = Vector2(200, 400)
	add_child(player)

	var tindera = TINDERA_SCRIPT.new()
	tindera.position = Vector2(500, 450)
	add_child(tindera)

	var tambay1 = TAMBAY_SCRIPT.new()
	tambay1.position = Vector2(750, 450)
	tambay1.line = "Dae, makipag-ilaila daw si Totong nimo. Type daw ka niya."
	add_child(tambay1)

	var tambay2 = TAMBAY_SCRIPT.new()
	tambay2.position = Vector2(900, 450)
	tambay2.line = "Ang laki naman ng watermelons mo."
	tambay2.followup_speaker = "Tindera"
	tambay2.followup_line = "Umayos kayo, bata pa 'to! Kayo tigulang na, iha pag-amping pauli."
	add_child(tambay2)

	var exit = SceneExit.new()
	exit.position = Vector2(1350, 450)
	exit.next_scene_path = "res://levels/02_habal_corner/HabalCorner.tscn"
	add_child(exit)
