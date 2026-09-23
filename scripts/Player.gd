extends CharacterBody2D

const SPEED = 180.0 # was 300 — slower, more deliberate walking pace
const SPRINT_SPEED_MULTIPLIER = 3.2 # 180 * 3.2 = 576 max sprint (was 600 — a tad slower)
const SPRINT_RAMP_TIME = 2.0 # seconds to go from walk speed to full sprint
# NOTE: Intended feature ni ang gradual increase sa speed.
const GRAVITY = 980.0
const JUMP_VELOCITY = -400.0

const RUN_FPS_MIN = 5.0  # Run animation speed right as sprinting begins
const RUN_FPS_MAX = 14.0 # Run animation speed at full sprint

# Slow "breathing" cycle for the exhaustion glow — deliberately gentle,
# not a blink/flash.
const EXHAUSTED_PULSE_SPEED = 3.0

@onready var stamina_bar = $UI/StaminaBar
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var max_stamina = 100.0
var current_stamina = 100.0
var stamina_drain_rate = 30.0
var stamina_regen_rate = 15.0

# True once stamina hits 0. Locks sprinting out entirely until stamina is
# back to full, so the player can't keep dipping into a partial bar for
# repeated short speed boosts — a real cost to burning it all.
var is_exhausted: bool = false
var _was_exhausted: bool = false # last frame's value, to catch the transition once
var pulse_time: float = 0.0
var stamina_fill_style: StyleBoxFlat
var stamina_bg_style: StyleBoxFlat

# Coral (empty) -> amber (getting low) -> teal (full/healthy). Sampled by
# current fraction each frame, so the bar eases through color rather than
# snapping between two fixed states.
var stamina_gradient: Gradient

# 0.0 = full walk pace, 1.0 = full sprint. Eases toward its target each
# frame instead of snapping, which is what makes both the speed and the
# animation feel like they're accelerating rather than toggling.
var sprint_blend: float = 0.0

# Interactables currently in range (populated by Interactable.gd).
var nearby_interactables: Array = []


func _ready() -> void:
	add_to_group("player")

	# The interact-prompt bar hides itself while dialogue is up; once a
	# conversation ends, ask it to show again if she's still standing
	# next to something.
	EventBus.dialogue_state_changed.connect(_on_dialogue_state_changed)

	stamina_gradient = Gradient.new()
	stamina_gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	stamina_gradient.colors = PackedColorArray([
		Color(0.86, 0.35, 0.38), # coral — near empty
		Color(0.92, 0.71, 0.36), # amber — running low
		Color(0.35, 0.78, 0.68), # teal — healthy
	])

	# Built in code so colors/glow can be updated live each frame without
	# hand-editing theme resources in the .tscn file.
	stamina_fill_style = StyleBoxFlat.new()
	stamina_fill_style.bg_color = stamina_gradient.sample(1.0)
	# Square corners — old pixel game style, no rounding anywhere.
	stamina_bar.add_theme_stylebox_override("fill", stamina_fill_style)

	# A dark, slightly translucent backing so the bar reads clearly over
	# any level background, with a thin rim for definition.
	stamina_bg_style = StyleBoxFlat.new()
	stamina_bg_style.bg_color = Color(0.07, 0.08, 0.1, 0.75)
	stamina_bg_style.border_width_left = 2
	stamina_bg_style.border_width_right = 2
	stamina_bg_style.border_width_top = 2
	stamina_bg_style.border_width_bottom = 2
	stamina_bg_style.border_color = Color(0, 0, 0, 0.45)
	stamina_bar.add_theme_stylebox_override("background", stamina_bg_style)

	# Punch pivots around its own center rather than its top-left corner.
	stamina_bar.pivot_offset = stamina_bar.size / 2.0


func register_interactable(i: Node) -> void:
	if not nearby_interactables.has(i):
		nearby_interactables.append(i)
	_refresh_interact_prompt()


func unregister_interactable(i: Node) -> void:
	nearby_interactables.erase(i)
	_refresh_interact_prompt()


## Tells the shared bottom-screen prompt bar what to show — the nearest
## registered interactable (index 0, same one E would trigger), or hides
## it if nothing's in range. Never shows it while dialogue is active.
func _refresh_interact_prompt() -> void:
	if EventBus.dialogue_active:
		return
	if nearby_interactables.size() > 0:
		var target: Node = nearby_interactables[0]
		EventBus.show_interact_prompt(target.interact_key_label, target.prompt_text)
	else:
		EventBus.hide_interact_prompt()


func _on_dialogue_state_changed(active: bool) -> void:
	if active:
		EventBus.hide_interact_prompt()
	else:
		_refresh_interact_prompt()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Reads EventBus instead of looking up the DialogueBox node directly —
	# Player.gd doesn't need to know it exists, just whether a
	# conversation is active.
	var dialogue_active = EventBus.dialogue_active

	# Freeze walking/sprinting input while a dialogue line or choice is on
	# screen, so she doesn't wander off mid-conversation.
	var direction := 0.0
	if not dialogue_active:
		direction = Input.get_axis("move_left", "move_right")

	if not dialogue_active and Input.is_action_just_pressed("interact") and nearby_interactables.size() > 0:
		nearby_interactables[0].interact()

	# Enter exhaustion the instant stamina bottoms out; only clear it once
	# stamina has climbed all the way back to max (not just "some").
	if current_stamina <= 0.0:
		is_exhausted = true
	elif is_exhausted and current_stamina >= max_stamina:
		is_exhausted = false

	var wants_to_sprint = (
		Input.is_action_pressed("sprint")
		and direction != 0
		and current_stamina > 0
		and not is_exhausted
	)

	# Ease sprint_blend toward 1 while sprinting, or back toward 0 when not
	# (exhaustion counts as "not", so she eases back down instead of
	# stopping dead the moment stamina hits zero).
	var target_blend = 1.0 if wants_to_sprint else 0.0
	sprint_blend = move_toward(sprint_blend, target_blend, delta / SPRINT_RAMP_TIME)

	var current_speed = lerp(SPEED, SPEED * SPRINT_SPEED_MULTIPLIER, sprint_blend)

	if wants_to_sprint:
		current_stamina -= stamina_drain_rate * sprint_blend * delta
	else:
		current_stamina += stamina_regen_rate * delta

	current_stamina = clamp(current_stamina, 0.0, max_stamina)
	update_stamina_bar(delta)

	if direction:
		velocity.x = direction * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)

	move_and_slide()

	update_animation(direction)


func update_stamina_bar(delta: float) -> void:
	stamina_bar.value = current_stamina

	var fraction = current_stamina / max_stamina
	var current_color = stamina_gradient.sample(fraction)
	stamina_fill_style.bg_color = current_color

	if is_exhausted:
		pulse_time += delta
		# Soft outward glow that breathes in and out — reads as "struggling
		# to catch her breath" without any hard flashing.
		var pulse = 0.5 + 0.5 * sin(pulse_time * EXHAUSTED_PULSE_SPEED)
		stamina_fill_style.shadow_color = Color(current_color.r, current_color.g, current_color.b, 0.4 * pulse)
		stamina_fill_style.shadow_size = lerp(2.0, 7.0, pulse)
	else:
		pulse_time = 0.0
		stamina_fill_style.shadow_color = Color(current_color.r, current_color.g, current_color.b, 0.18)
		stamina_fill_style.shadow_size = 3.0

	# Fires once, exactly on the frame she bottoms out — a quick tactile
	# snap so hitting zero actually registers as a moment, then settles
	# back into the steady breathing glow above.
	if is_exhausted and not _was_exhausted:
		_punch_stamina_bar()
	_was_exhausted = is_exhausted


func _punch_stamina_bar() -> void:
	var tween = create_tween()
	tween.tween_property(stamina_bar, "scale", Vector2(1.08, 1.3), 0.07) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(stamina_bar, "scale", Vector2.ONE, 0.28) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func update_animation(direction: float) -> void:
	if direction != 0:
		animated_sprite.flip_h = direction < 0

	if not is_on_floor():
		if animated_sprite.sprite_frames.has_animation("Jump"):
			animated_sprite.play("Jump")
		return

	if direction == 0:
		sprint_blend = 0.0 # standing still resets the ramp cleanly
		animated_sprite.play("Idle")
		return

	if sprint_blend > 0.0 and animated_sprite.sprite_frames.has_animation("Run"):
		# Same blend value drives the animation speed as drives movement
		# speed, so the legs visibly speed up as she actually gets faster.
		var run_fps = lerp(RUN_FPS_MIN, RUN_FPS_MAX, sprint_blend)
		animated_sprite.sprite_frames.set_animation_speed("Run", run_fps)
		animated_sprite.play("Run")
	elif animated_sprite.sprite_frames.has_animation("Walk"):
		animated_sprite.play("Walk")
	else:
		animated_sprite.play("Idle")
