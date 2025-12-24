extends CharacterBody3D

@export var speed := 5.0
@export var sprint_multiplier := 1.5
@export var jump_velocity := 4.5

var direction : Vector3

var start_jbuffer_timer := 0.1
@onready var jump_buffer_timer : Timer = $JumpBuffer
var start_coyotee_timer := 0.1
@onready var coyotee_timer : Timer = $Coyotee

func _input(event: InputEvent) -> void:
	var inputdir = Input.get_vector("left", "right", "up", "down")
	direction = transform.basis * Vector3(inputdir.x, 0, inputdir.y)
	direction = direction.normalized()
	
	if event.is_action_pressed("jump") and coyotee_timer.time_left > 0:
		jump_buffer_timer.start(start_jbuffer_timer)
	

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if jump_buffer_timer.time_left > 0 and is_on_floor():
		velocity.y = jump_velocity

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
