extends CharacterBody3D

#Flying
var flying := false
@export var flying_speed := 10

#GroundMovement
@export var speed := 5.0
var actual_speed : float
@export var acceleration := 1.0
var actual_acceleration : float
@export var sprint_multiplier := 3.0
var sprinting : bool

var jumping : bool 
var falling : bool
@export var jump_velocity := 10.5
@export var gravity := 40.0
@export var fall_multiplier := 2.0

var last_move_direction := Vector3.FORWARD
var input_dir : Vector2
var vertical_input : float
var horizontal_move_dir : Vector3
var vertical_move_dir : Vector3

#Timers
var start_jbuffer_time := 0.1
@onready var jump_buffer_timer : Timer = $JumpBuffer
var start_coyotee_time := 0.1
@onready var coyotee_timer : Timer = $Coyotee
@export var jump_hold_time := 0.2
@onready var jump_hold_timer : Timer = $JumpHold

#Camera Movement
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/SpringArm3D/Camera3D
@export var sensitivity : float = 0.01
@onready var model: Node3D = $Model

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	actual_speed = speed
	actual_acceleration = acceleration

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if event.is_action_pressed("quit"):
		get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	input_dir = Input.get_vector("left", "right", "up", "down")
	vertical_input = Input.get_axis("crouch", "jump")
	
	if event.is_action_pressed("shoot"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var camera_input_dir = event.screen_relative * sensitivity
		head.rotation.x -= camera_input_dir.y
		head.rotation.y -= camera_input_dir.x
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-89), deg_to_rad(45))
	
	if event.is_action_pressed("jump"):
		jump_buffer_timer.start(start_jbuffer_time)
		#fly start
		if coyotee_timer.time_left == 0 and !flying:
			if actual_speed == speed:
				actual_speed = flying_speed
			elif actual_speed == speed * sprint_multiplier:
				actual_speed = flying_speed * sprint_multiplier
			flying = true
	elif  event.is_action_released("jump"):
		jumping = false
		falling = true
	
	if event.is_action_pressed("sprint"):
		actual_speed = speed * sprint_multiplier
		actual_acceleration = acceleration * sprint_multiplier * 0.5
	elif event.is_action_released("sprint"):
		if flying:
			actual_speed = flying_speed
		else:
			actual_speed = speed
		actual_acceleration = acceleration


var forward : Vector3
var right : Vector3
var up : Vector3
func _process(delta: float) -> void:
	forward = camera.global_basis.z
	right = camera.global_basis.x
	up = camera.global_basis.y
	
	falling = velocity.y < 0 and !is_on_floor()
	
	if horizontal_move_dir.length() > 0.2:
		last_move_direction = horizontal_move_dir
		
	var camera_direction := global_position.direction_to(camera.global_position)
	if flying:
		var target_transform := model.global_transform.looking_at(model.global_position - camera_direction,Vector3.UP)
		model.global_transform = model.global_transform.interpolate_with(target_transform, 20 * delta)
		
	else:
		if abs(model.rotation.x) < 0.1 or abs(model.rotation.z) < 0.1:
			model.rotation = model.rotation.lerp(Vector3(0, model.rotation.y, 0), 0.5)
			var target_angle = Vector3.FORWARD.signed_angle_to(last_move_direction, Vector3.UP)
			model.rotation.y = lerp_angle(model.rotation.y, target_angle, 20 * delta)


func _physics_process(delta: float) -> void:
	horizontal_move_dir = forward * input_dir.y + right * input_dir.x
	vertical_move_dir = up * vertical_input
	
	if flying: 
		var fly_direction = (horizontal_move_dir + vertical_move_dir).normalized()
		velocity = velocity.move_toward(fly_direction * actual_speed, actual_acceleration)
	else:
		horizontal_move_dir.y = 0
		horizontal_move_dir = horizontal_move_dir.normalized()
		
		var y = velocity.y
		velocity = velocity.move_toward(horizontal_move_dir * actual_speed, actual_acceleration)
		velocity.y = y
	
	if is_on_floor():
		coyotee_timer.start(start_coyotee_time)
		
		if flying:
			flying = false
			
			if actual_speed == flying_speed:
				actual_speed = speed
			else:
				actual_speed = speed * sprint_multiplier
	else:
		if !flying:
			if !falling:
				velocity += Vector3(0, -gravity, 0) * delta
			else:
				velocity += Vector3(0, -gravity, 0) * delta * fall_multiplier
	
	#jump
	if jump_buffer_timer.time_left > 0 and coyotee_timer.time_left > 0:
		jumping = true
		jump_hold_timer.start(jump_hold_time)
	
	if jumping:
		if jump_hold_timer.time_left == 0:
			jumping = false
			falling = true	
		velocity.y = jump_velocity
		print(jump_hold_timer.time_left)
	move_and_slide()
