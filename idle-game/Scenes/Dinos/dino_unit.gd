extends CharacterBody3D

@export var move_speed: float = 1.8
@export var wander_radius: float = 6.0
@export var min_idle_time: float = 2.0
@export var max_idle_time: float = 5.0

var target_position: Vector3 = Vector3.ZERO
var is_moving: bool = false
var idle_timer: float = 0.0

func _ready() -> void:
	pick_new_destination()

func _physics_process(delta: float) -> void:
	if not is_moving:
		idle_timer -= delta
		if idle_timer <= 0.0:
			pick_new_destination()
		return

	var current_pos := global_position
	var to_target := target_position - current_pos
	to_target.y = 0.0

	var distance := to_target.length()
	if distance < 0.2:
		is_moving = false
		idle_timer = randf_range(min_idle_time, max_idle_time)
		velocity = Vector3.ZERO
		return

	var direction := to_target.normalized()
	velocity = direction * move_speed
	move_and_slide()

	# Smooth rotation facing target
	var target_rotation_y := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_rotation_y, delta * 6.0)

func pick_new_destination() -> void:
	var angle := randf() * TAU
	# Distance from center: between 2.5 (don't hit tree) and wander_radius
	var dist := randf_range(2.5, wander_radius)
	target_position = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
	is_moving = true
