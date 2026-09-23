class_name SceneExit
extends Area2D

## Walking into this area sends the player to the next scene. Place one
## at the edge of a level and set next_scene_path to the following level.

@export var next_scene_path: String = ""
@export var exit_size: Vector2 = Vector2(60, 220)


func _ready() -> void:
	collision_layer = 0
	set_collision_mask_value(1, true)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = exit_size
	shape.shape = rect
	add_child(shape)

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)
