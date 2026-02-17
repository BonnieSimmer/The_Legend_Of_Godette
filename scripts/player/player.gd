extends CharacterBody3D

@export_group("Jump")
@export var jump_height : float = 2.25
@export var jump_time_to_peak : float = 0.4
@export var jump_time_to_descent : float = 0.3

@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak)
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

@export_group("Movement")
@export var base_speed := 4.0
@export var run_speed := 6.0
@export var defend_speed := 2.0
var speed_modifier := 1.0

@onready var camera := $CameraController/Camera3D
@onready var skin := $GodetteSkin

var movement_input := Vector2.ZERO
var defend := false:
	set(value): 
		if not defend and value:
			skin.defend(true)
		if defend and not value:
			skin.defend(false)
		defend = value
var weapon_active := false
		
func _physics_process(delta: float) -> void:
	move_logic(delta)
	jump_logic(delta)
	
	ability_logic()
	
	move_and_slide() 
	
func move_logic(delta: float) -> void:
	movement_input = Input.get_vector("left","right","forward","backward").rotated(-camera.global_rotation.y)
	var velocity_2d := Vector2(velocity.x, velocity.z)
	
	var is_running := Input.is_action_pressed("run")
	var speed := run_speed if is_running else base_speed
	speed = defend_speed if defend else speed

	if movement_input != Vector2.ZERO:
		velocity_2d += movement_input * speed * delta * 8.0
		velocity_2d = velocity_2d.limit_length(speed) * speed_modifier
		skin.set_move_state("Running")
		var target_angel := -movement_input.angle() + PI/2
		skin.rotation.y = rotate_toward( skin.rotation.y, target_angel, delta * 6.0)
	else:           
		var friction: float = 4.0 if is_on_floor() else 0.5
		velocity_2d = velocity_2d.move_toward(Vector2.ZERO, speed * delta * friction)   
		skin.set_move_state("Idle")
	velocity.x = velocity_2d.x
	velocity.z = velocity_2d.y

func jump_logic(delta: float) -> void:
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
			do_squash_and_stretch(1.2, 0.15)
	else:
		skin.set_move_state("Jump")
	var gravity := jump_gravity if velocity.y > 0.0 else fall_gravity
	velocity.y -= gravity * delta
	
func ability_logic() -> void:
	# Actual attack
	if Input.is_action_just_pressed("ability"):
		if weapon_active:
			skin.attack()
		else:
			skin.cast_spell()
			stop_movement(0.3, 0.8)
	# Defend
	defend = Input.is_action_pressed("block")
	# Switch weapon/magic
	if Input.is_action_just_pressed("switch weapon") and not skin.attacking:
		weapon_active = not weapon_active
		skin.switch_weapon(weapon_active)
		do_squash_and_stretch(1.1, 0.15)
				
func stop_movement(start_duration: float, end_duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(self, "speed_modifier", 0.0, start_duration)
	tween.tween_property(self, "speed_modifier", 1.0, end_duration)	
	
func hit() -> void:
	skin.hit()
	stop_movement(0.3, 0.3)
	
func do_squash_and_stretch(value: float, duration: float = 0.1) -> void:
	var tween := create_tween()
	tween.tween_property(skin, "squash_and_stretch", value, duration)
	tween.tween_property(skin, "squash_and_stretch", 1.0, duration * 1.8).set_ease(Tween.EASE_OUT) 
	