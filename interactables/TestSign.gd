extends Interactable

## Just for trying out the interact + dialogue system in Main.tscn.
## Walk up, press E, pick a choice.


func _ready() -> void:
	prompt_text = "Test interact + dialogue"

	var label := Label.new()
	label.text = "[Test Sign]"
	label.position = Vector2(-40, -80)
	add_child(label)

	super._ready()


func interact() -> void:
	await EventBus.say("???", "Hoy, dae! Diin ka paingon?")
	var choice: int = await EventBus.ask(
		"Paulina",
		"Mutubag ka ba niya?",
		["Ignore him", "Respond"]
	)
	EventBus.hide_dialogue()

	if choice == 0:
		await EventBus.say("Paulina", "(Gi-ignore lang niya ug nagpadayon sa paglakaw.)")
	else:
		await EventBus.say("Paulina", "Unsa may gusto nimo?")
		await EventBus.say("???", "Wala ra, sige lang. Pag-amping.")

	EventBus.hide_dialogue()
