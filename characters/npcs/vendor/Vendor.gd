extends NPC

# Placeholder rani sha. do what you want with dis dude.dd

func _init() -> void:
	npc_name = "Vendor"
	prompt_text = "Talk to the Vendor"

	portrait_prefix = "res://characters/npcs/vendor/vendor_portrait_sprite/vendor_portrait_idle_"
	portrait_frame_count = 16

	player_portrait_prefix = "res://characters/paulina/player_portrait_sprite/player_idle_portrait_"
	player_portrait_frame_count = 18

	first_lines = [
		DialogueLine.new("Vendor", "Nganong di mo gana akong dc dae."),
		DialogueLine.new("Paulina", "Tungod daws mga bata nag pinusilay."),
		DialogueLine.new("Vendor", "K"),
	]
	repeat_lines = [
		DialogueLine.new("Vendor", "Yes to fox silic"),
	]
