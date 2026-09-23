extends Interactable

## Scene 5's house gate. Three keys on the keychain, one is correct (the
## worn brass key). Three wrong attempts total and the sikad driver
## catches up — Bad Ending. Pick right — Safe Ending.

const CORRECT_INDEX := 0 # "Worn brass key"

var attempts_left := 3


func _ready() -> void:
	prompt_text = "Try the gate"
	interaction_radius = 60.0
	super._ready()


func interact() -> void:
	if attempts_left <= 0:
		return

	await EventBus.say("Paulina", "(Naa'y tulo ka yawi sa akong keychain. Kinsa ba ni?)")
	var choice: int = await EventBus.ask(
		"Paulina",
		"Attempts left: %d" % attempts_left,
		["Worn brass key", "Small cabinet key", "Modern silver key"]
	)
	EventBus.hide_dialogue()

	if choice == CORRECT_INDEX:
		LevelUtils.go_to_ending(
			get_tree(),
			"Safe Ending",
			"The old brass key clicks into place. The gate swings open, and Paulina steps safely inside."
		)
		return

	attempts_left -= 1
	if attempts_left <= 0:
		LevelUtils.go_to_ending(
			get_tree(),
			"Bad Ending",
			"The wrong keys keep failing. Footsteps close in behind her as the screen fades to black."
		)
	else:
		await EventBus.say("Paulina", "(Dili ni ang tarong yawi...)")
		EventBus.hide_dialogue()
