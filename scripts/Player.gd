extends CharacterBody2D

const SPEED = 300.0
const GRAVITY = 980.0
const JUMP_VELOCITY = -400.0

@onready var stamina_bar = $UI/StaminaBar
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var max_stamina = 100.0
var current_stamina = 100.0
var stamina_drain_rate = 30.0
var stamina_regen_rate = 15.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("move_left", "move_right")

	var current_speed = SPEED
	var is_sprinting = Input.is_action_pressed("sprint") and direction != 0

	if is_sprinting and current_stamina > 0:
		current_speed *= 2.0
		current_stamina -= stamina_drain_rate * delta
	else:
		current_stamina += stamina_regen_rate * delta

	current_stamina = clamp(current_stamina, 0.0, max_stamina)
	stamina_bar.value = current_stamina

	if direction:
		velocity.x = direction * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)

	move_and_slide()

	update_animation(direction, is_sprinting)


func update_animation(direction: float, is_sprinting: bool) -> void:
	if direction != 0:
		animated_sprite.flip_h = direction < 0

	if not is_on_floor():
		if animated_sprite.sprite_frames.has_animation("Jump"):
			animated_sprite.play("Jump")
		return

	if direction == 0:
		animated_sprite.play("Idle")
		return

	if is_sprinting and current_stamina > 0:
		if animated_sprite.sprite_frames.has_animation("Run"):
			animated_sprite.play("Run")
		else:
			animated_sprite.play("Walk")
	else:
		if animated_sprite.sprite_frames.has_animation("Walk"):
			animated_sprite.play("Walk")
		else:
			animated_sprite.play("Idle")
