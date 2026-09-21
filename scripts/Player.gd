extends CharacterBody2D

#iedit lang diri if di mo ganahan sa speed and grav
const SPEED = 300.0
const GRAVITY = 980.0
const JUMP_VELOCITY = -400.0

@onready var stamina_bar = $UI/StaminaBar

var max_stamina = 100.0
var current_stamina = 100.0
var stamina_drain_rate = 30.0
var stamina_regen_rate = 15.0

func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Handle Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# para ni input
	var direction := Input.get_axis("move_left", "move_right")
	
	var current_speed = SPEED
	var is_sprinting = Input.is_action_pressed("sprint") and direction != 0
	
	#machange diri kung pila ang speed sa sprint
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
