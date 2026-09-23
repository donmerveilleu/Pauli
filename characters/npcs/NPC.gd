class_name NPC
extends Interactable

## Base class for characters whose interact() is just "show some
## dialogue lines" (HabalDriver, Tambay, Tindera, Vendor). Subclasses set
## the exported fields below — in _init(), in _ready(), or from the
## Inspector on a .tscn — instead of hardcoding dialogue.say(...) calls
## and a get_first_node_in_group("dialogue_box") lookup in every script.
##
## For anything that branches (choices, endings, stat checks — e.g.
## Stranger.gd) subclasses can still override interact() completely and
## just use the say()/ask() helpers below to stay decoupled from
## DialogueBox.

## Shown as the speaker name for any DialogueLine that leaves `speaker`
## blank.
@export var npc_name: String = ""

## Optional animated portrait for this NPC, built the same way
## LevelUtils.load_portrait() expects: a numbered PNG sequence prefix
## plus how many frames it has.
@export var portrait_prefix: String = ""
@export var portrait_frame_count: int = 0
@export var portrait_frame_digits: int = 4
@export var portrait_fps: float = 8.0

## Optional second portrait for lines spoken by Paulina herself (e.g. the
## Vendor exchange, where her reply shows her own portrait rather than
## the NPC's).
@export var player_portrait_prefix: String = ""
@export var player_portrait_frame_count: int = 0

## Lines played the first time the player interacts.
@export var first_lines: Array[DialogueLine] = []
## Lines played on every interaction after the first. Leave empty to
## just replay first_lines again on every visit.
@export var repeat_lines: Array[DialogueLine] = []

var portrait: Texture2D
var player_portrait: Texture2D
var _talked: bool = false


func _ready() -> void:
	if portrait_prefix != "" and portrait_frame_count > 0:
		portrait = LevelUtils.load_portrait(
			portrait_prefix, portrait_frame_count, portrait_frame_digits, portrait_fps
		)
	if player_portrait_prefix != "" and player_portrait_frame_count > 0:
		player_portrait = LevelUtils.load_portrait(player_portrait_prefix, player_portrait_frame_count)

	super._ready()


## Default behaviour: play first_lines once, then repeat_lines (or
## first_lines again if no repeat_lines were set) on every visit after
## that. Override this entirely for anything branchier — see Stranger.gd.
func interact() -> void:
	var lines := first_lines if not _talked else (repeat_lines if not repeat_lines.is_empty() else first_lines)

	for line in lines:
		await say(line.speaker if line.speaker != "" else npc_name, line.text, _portrait_for(line))

	_talked = true
	EventBus.hide_dialogue()


func _portrait_for(line: DialogueLine) -> Texture2D:
	if line.speaker == "" or line.speaker == npc_name:
		return portrait
	if line.speaker == "Paulina":
		return player_portrait
	return null


## Thin wrappers around EventBus so subclasses never touch DialogueBox
## directly — this is what keeps NPC scripts decoupled from the UI.
func say(speaker: String, text: String, custom_portrait: Texture2D = null) -> void:
	await EventBus.say(speaker, text, custom_portrait)


func ask(speaker: String, text: String, choices: Array, custom_portrait: Texture2D = null) -> int:
	return await EventBus.ask(speaker, text, choices, custom_portrait)
