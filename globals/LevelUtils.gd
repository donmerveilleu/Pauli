class_name LevelUtils
extends RefCounted

## Small static helpers shared by level scripts. This is NOT an autoload —
## it's just a globally-registered utility class (via class_name), so any
## script can call LevelUtils.something() directly without preloading it.
## Kept deliberately separate from any GameManager/state-tracking system.


## Builds a simple placeholder floor: a StaticBody2D with a rectangular
## collider and a matching visual ColorRect — same pattern as the original
## test scene (Main.tscn), just reusable across levels.
static func create_floor(parent: Node, center_position: Vector2, size: Vector2) -> StaticBody2D:
	var floor_body := StaticBody2D.new()
	floor_body.name = "Floor"
	floor_body.position = center_position
	parent.add_child(floor_body)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	floor_body.add_child(collision)

	var visual := ColorRect.new()
	visual.color = Color(0.85, 0.85, 0.85)
	visual.size = size
	visual.position = -size / 2.0
	floor_body.add_child(visual)

	return floor_body


## Loads a numbered PNG sequence (e.g. "..._0001.png" .. "..._0016.png") as
## a looping AnimatedTexture, for use as a DialogueBox portrait. Pass
## everything up to and including the trailing underscore as path_prefix:
##   LevelUtils.load_portrait(
##       "res://characters/npcs/vendor/vendor_portrait_sprite/vendor_portrait_idle_", 16
##   )
static func load_portrait(path_prefix: String, frame_count: int, digits: int = 4, fps: float = 8.0) -> Texture2D:
	var anim := AnimatedTexture.new()
	anim.frames = frame_count
	anim.speed_scale = fps

	for i in frame_count:
		var frame_number := str(i + 1).pad_zeros(digits)
		var tex: Texture2D = load("%s%s.png" % [path_prefix, frame_number])
		if tex:
			anim.set_frame_texture(i, tex)

	return anim


## Swaps the currently running scene for the shared ending screen, with a
## custom title/body baked in at swap time. No autoload/global state
## needed — just direct SceneTree manipulation.
static func go_to_ending(tree: SceneTree, title: String, text: String) -> void:
	var EndingScreenScript = preload("res://ui/endings/EndingScreen.gd")
	var instance = EndingScreenScript.new()
	instance.ending_title = title
	instance.ending_text = text

	tree.root.add_child(instance)
	tree.current_scene.queue_free()
	tree.current_scene = instance
