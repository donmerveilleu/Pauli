class_name DialogueLine
extends Resource

## One line of dialogue: who says it, and what they say. Used by NPC.gd's
## exported `first_lines` / `repeat_lines` arrays instead of hardcoding
## dialogue.say(...) calls in every NPC script.

@export var speaker: String = ""
@export_multiline var text: String = ""


func _init(p_speaker: String = "", p_text: String = "") -> void:
	speaker = p_speaker
	text = p_text
