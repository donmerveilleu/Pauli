class_name EndingScreen
extends CanvasLayer

## Full-screen black ending card. Don't instance this directly in a level —
## use LevelUtils.go_to_ending(get_tree(), title, text) instead, which
## swaps the running scene for one of these with the text baked in.

@export var ending_title: String = "The End"
@export var ending_text: String = ""


func _ready() -> void:
	layer = 20

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	bg.add_child(vbox)

	var title_label := Label.new()
	title_label.text = ending_title
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	var text_label := Label.new()
	text_label.text = ending_text
	text_label.add_theme_font_size_override("font_size", 18)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_label.custom_minimum_size = Vector2(560, 0)
	vbox.add_child(text_label)

	var restart_label := Label.new()
	restart_label.text = "(Restart the game to try again)"
	restart_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restart_label.modulate = Color(1, 1, 1, 0.5)
	vbox.add_child(restart_label)
