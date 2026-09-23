extends Node2D

## SCAFFOLD — Scenes 3 & 4 from the design doc: a man matching her pace,
## the sikad driver reappearing and grabbing her, then a chase through an
## obstacle-filled alley (narrow gaps, garbage bags, stray dogs, flickering
## lights) while managing stamina. This is a real system on its own —
## pursuit logic, obstacle collision, a catch/fail loop — and deserves its
## own dedicated build rather than a rushed version here.
##
## For now this keeps the scene-to-scene flow playable end to end.

const PLAYER_SCENE = preload("res://scenes/Player.tscn")
const DIALOGUE_BOX_SCRIPT = preload("res://ui/dialogue/DialogueBox.gd")


func _ready() -> void:
	LevelUtils.create_floor(self, Vector2(700, 500), Vector2(1600, 50))

	var dialogue = DIALOGUE_BOX_SCRIPT.new()
	add_child(dialogue)

	var player = PLAYER_SCENE.instantiate()
	player.position = Vector2(150, 400)
	add_child(player)

	var todo_label := Label.new()
	todo_label.text = "TODO: chase sequence\n(man following, sikad driver grab,\nobstacle alley, flickering lights)"
	todo_label.position = Vector2(150, 250)
	add_child(todo_label)

	var exit = SceneExit.new()
	exit.position = Vector2(1350, 450)
	exit.next_scene_path = "res://levels/06_house_gates/HouseGates.tscn"
	add_child(exit)
