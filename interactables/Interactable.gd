class_name Interactable
extends Area2D

## Base class for anything Paulina can interact with — NPCs, signs, the
## gate at the end, etc. Extend this and override interact().
##
## The "[E] ..." prompt itself isn't built here anymore — it lives as a
## single shared bar docked to the bottom of the screen (owned by
## DialogueBox, which already sits in the same HUD layer as the
## dialogue box). This class just tracks proximity and, via the player,
## tells EventBus what that shared bar should say. That keeps every
## interactable in the game looking and behaving the same without each
## one building its own floating UI over its head.
##
## Set auto_trigger = true for things that should fire the moment the
## player gets close, with no prompt — e.g. a figure who calls out to
## Paulina as she approaches, rather than something she has to press E on.

## Just the action, not the key — e.g. "Talk to the Vendor", "Try the
## gate". The prompt renders as a key cap for `interact_key_label` in
## front of this, so don't repeat "Press E" in here.
@export var prompt_text: String = "Interact"
## What the key cap shows. Change this if a subclass ever wants to
## advertise a different bound action.
@export var interact_key_label: String = "E"
@export var interaction_radius: float = 48.0
@export var auto_trigger: bool = false

var _triggered: bool = false


func _ready() -> void:
	# Detect the player (layer 1) without being detectable itself.
	collision_layer = 0
	set_collision_mask_value(1, true)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = interaction_radius
	shape.shape = circle
	add_child(shape)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	if auto_trigger:
		if not _triggered:
			_triggered = true
			interact()
		return

	if body.has_method("register_interactable"):
		body.register_interactable(self)


func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("unregister_interactable"):
		body.unregister_interactable(self)


## Override this in subclasses — this is what runs when the player
## presses E in range (or on approach, if auto_trigger is set).
func interact() -> void:
	pass
