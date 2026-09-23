extends Node2D

## "Map creator" scratch level. Test NPCs/interactables live here as real,
## authored child nodes (see the Scene dock) — not spawned by script — so
## they're visible and draggable in the editor without pressing Play.
##
## To add the next one: give it its own .tscn (script + sprite, like
## Vendor.tscn), then instance it as a child of Main here and place it
## further along the floor.

const DIALOGUE_BOX_SCRIPT = preload("res://ui/dialogue/DialogueBox.gd")


func _ready() -> void:
	# The only thing still built in code — it has no visual until a line
	# of dialogue is actually triggered, so there's nothing to see by
	# authoring it in the editor.
	var dialogue = DIALOGUE_BOX_SCRIPT.new()
	add_child(dialogue)
