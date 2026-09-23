extends Node

## Autoload/singleton event bus (see project.godot -> [autoload]).
##
## Decouples the game world from the UI: interactables (NPCs, the gate,
## signs, ...) never hold a reference to DialogueBox, and DialogueBox
## never holds a reference to whatever interactable is talking. Both
## sides only know about EventBus.
##
## Interactables call the say()/ask()/hide_dialogue() wrappers below
## instead of fetching the dialogue node and calling methods on it
## directly:
##
##   await EventBus.say("Tindera", "Sige, iha. Eto na, sukli ni nimo.")
##
##   var choice = await EventBus.ask("Paulina", "Unsa imong buhaton?",
##       ["Ignore and keep walking", "Turn around and respond"])
##
## DialogueBox.gd listens on the request signals and reports results back
## through dialogue_advanced / dialogue_choice_made rather than being
## called directly.

signal dialogue_line_requested(speaker: String, text: String, portrait: Texture2D)
signal dialogue_choice_requested(speaker: String, text: String, choices: Array, portrait: Texture2D)
signal dialogue_advanced
signal dialogue_choice_made(index: int)
signal dialogue_hide_requested
signal dialogue_state_changed(active: bool)

## The bottom-of-screen "[E] ..." prompt is owned by DialogueBox now (it
## lives in the same HUD sheet as the dialogue box itself), so
## Interactable/Player never touch that UI directly — they just say
## what should be showing.
signal interact_prompt_requested(key_label: String, prompt_text: String)
signal interact_prompt_hide_requested

## Mirrors whether a DialogueBox is currently showing a line/choice, kept
## in sync via set_dialogue_active() below. Player.gd reads this instead
## of reaching into the dialogue node to ask is_dialogue_active().
var dialogue_active: bool = false


func set_dialogue_active(active: bool) -> void:
	if dialogue_active == active:
		return
	dialogue_active = active
	dialogue_state_changed.emit(active)


## Shows a single line and waits for the player to advance past it.
func say(speaker: String, text: String, portrait: Texture2D = null) -> void:
	dialogue_line_requested.emit(speaker, text, portrait)
	await dialogue_advanced


## Shows a choice prompt and waits for (and returns) the index picked.
func ask(speaker: String, text: String, choices: Array, portrait: Texture2D = null) -> int:
	dialogue_choice_requested.emit(speaker, text, choices, portrait)
	return await dialogue_choice_made


func hide_dialogue() -> void:
	dialogue_hide_requested.emit()


func show_interact_prompt(key_label: String, prompt_text: String) -> void:
	interact_prompt_requested.emit(key_label, prompt_text)


func hide_interact_prompt() -> void:
	interact_prompt_hide_requested.emit()
