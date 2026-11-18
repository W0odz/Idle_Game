extends Node3D

@export_group("Orbit Settings")
@export var orbit_speed: float = 0.005
@export var pitch_min: float = -75.0
@export var pitch_max: float = -10.0

@export_group("Zoom Settings")
@export var zoom_speed: float = 1.0
@export var min_distance: float = 6.0
@export var max_distance: float = 22.0
@export var smooth_factor: float = 10.0

@onready var pitch_pivot: Node3D = $PitchPivot
@onready var camera: Camera3D = $PitchPivot/Camera3D

var is_dragging: bool = false
var target_yaw: float = 0.0
var target_pitch: float = -30.0
var target_distance: float = 14.0
var current_distance: float = 14.0

func _ready() -> void:
	target_yaw = rotation.y
	target_pitch = pitch_pivot.rotation_degrees.x
	current_distance = camera.position.z
	target_distance = current_distance

func _unhandled_input(event: InputEvent) -> void:
	# Mouse / Touch Dragging
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or (event.button_index == MOUSE_BUTTON_LEFT and Input.is_key_pressed(KEY_SHIFT)):
			is_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_distance = clampf(target_distance - zoom_speed, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_distance = clampf(target_distance + zoom_speed, min_distance, max_distance)

	elif event is InputEventMouseMotion and is_dragging:
		target_yaw -= event.relative.x * orbit_speed
		target_pitch = clampf(target_pitch - event.relative.y * (orbit_speed * 50.0), pitch_min, pitch_max)

	# Mobile Touch Pinch / Drag support
	elif event is InputEventScreenDrag:
		target_yaw -= event.relative.x * orbit_speed
		target_pitch = clampf(target_pitch - event.relative.y * (orbit_speed * 50.0), pitch_min, pitch_max)

func _process(delta: float) -> void:
	# Smooth interpolation for orbit and zoom
	rotation.y = lerp_angle(rotation.y, target_yaw, delta * smooth_factor)
	pitch_pivot.rotation_degrees.x = lerpf(pitch_pivot.rotation_degrees.x, target_pitch, delta * smooth_factor)
	
	current_distance = lerpf(current_distance, target_distance, delta * smooth_factor)
	camera.position.z = current_distance
