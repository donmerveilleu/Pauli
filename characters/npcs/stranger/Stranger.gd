extends NPC

## Scene 2's dark alley figure — this is the design doc's actual "trust
## your instincts" branch point. Ignoring him lets her pass safely;
## responding leads straight to the Bad Ending, per the design doc.
##
## Branches to an ending, so it overrides interact() entirely rather than
## using NPC's default first_lines/repeat_lines playback — but it still
## reaches the dialogue system only through the inherited say()/ask()
## helpers, so it stays just as decoupled from DialogueBox as the simpler
## NPCs.


func _init() -> void:
	npc_name = "???"
	auto_trigger = true
	interaction_radius = 100.0


func interact() -> void:
	await say("???", "Miss... palita ni akong gibaligya. Pangkaon lang sa akong pamilya.")
	var choice: int = await ask(
		"Paulina",
		"Unsa imong buhaton?",
		["Ignore and keep walking", "Turn around and respond"]
	)
	EventBus.hide_dialogue()

	if choice == 0:
		await say("Paulina", "(Wala siya mitubag ug nagpadayon lang og lakaw. Luwas siyang nakaagi.)")
		EventBus.hide_dialogue()
	else:
		LevelUtils.go_to_ending(
			get_tree(),
			"Bad Ending",
			"You hesitated. In the dark, a moment is all it takes."
		)
