extends NPC

## Auto-fires as Paulina walks past — no "Press E" needed, since these guys
## don't wait to be asked. Place a few in Terminal.gd with different
## `line` values. Set followup_speaker/followup_line on the last one to
## chain in the Tindera's scolding right after.

@export var line: String = "Dae, makipag-ilaila daw si Totong nimo. Type daw ka niya."
@export var followup_speaker: String = ""
@export var followup_line: String = ""


func _init() -> void:
	npc_name = "Tambay"
	auto_trigger = true
	interaction_radius = 90.0


func _ready() -> void:
	# line/followup_* are set by the level script right after .new(), so
	# build first_lines here (after those assignments, before the base
	# class wires up collision + prompt in its own _ready()).
	first_lines = [DialogueLine.new("Tambay", line)]
	if followup_line != "":
		first_lines.append(DialogueLine.new(followup_speaker, followup_line))

	super._ready()
