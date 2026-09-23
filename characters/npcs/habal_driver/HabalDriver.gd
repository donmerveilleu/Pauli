extends NPC

## Scene 1.2's habal/sikad driver — insists on giving her a ride, she
## refuses and keeps walking. (His later, more threatening reappearance in
## Scene 3 belongs in the chase-alley scaffold, not here.)


func _init() -> void:
	npc_name = "Sikad Driver"
	auto_trigger = true
	interaction_radius = 90.0

	first_lines = [
		DialogueLine.new("Sikad Driver", "Dae, sakay na lang. Gabii na kaayo, ngitngit pa gyud. Daghan ra ba'y babae na biktima diha. Libre ra, paingon man sad ko uli, duol ra man ta balay."),
		DialogueLine.new("Paulina", "Dili lang ko, kuya. Maglakaw ra man among balay."),
		DialogueLine.new("Sikad Driver", "Sigurado ka, dae? Delikado kaayo mag-inusara ron."),
		DialogueLine.new("Paulina", "(Gi-ignore niya ug nagpadayon sa paglakaw.)"),
	]
