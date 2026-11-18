extends Node3D

@export_group("Orbit Settings")
@export var orbit_speed: float = 0.005
@export var pitch_min: float = -75.0
@export var pitch_max: float = -10.0

@export_group("Zoom Settings")
@export var zoom_speed: float = 1.0
@export var pinch_zoom_sensitivity: float = 0.02
@export var min_distance: float = 6.0
@export var max_distance: float = 22.0
@export var smooth_factor: float = 10.0

@onready var pitch_pivot: Node3D = $PitchPivot
@onready var camera: Camera3D = $PitchPivot/Camera3D

var is_dragging_mouse: bool = false
var target_yaw: float = 0.0
var target_pitch: float = -30.0
var target_distance: float = 14.0
var current_distance: float = 14.0

# Multi-touch tracking dictionary: touch_index (int) -> Vector2 (position)
var touch_points: Dictionary = {}

func _ready() -> void:
	target_yaw = rotation.y
	target_pitch = pitch_pivot.rotation_degrees.x
	current_distance = camera.position.z
	target_distance = current_distance

func _unhandled_input(event: InputEvent) -> void:
	# --- 1. PC MOUSE CONTROLS ---
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or (event.button_index == MOUSE_BUTTON_LEFT and Input.is_key_pressed(KEY_SHIFT)):
			is_dragging_mouse = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_distance = clampf(target_distance - zoom_speed, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_distance = clampf(target_distance + zoom_speed, min_distance, max_distance)

	elif event is InputEventMouseMotion and is_dragging_mouse:
		target_yaw -= event.relative.x * orbit_speed
		target_pitch = clampf(target_pitch - event.relative.y * (orbit_speed * 50.0), pitch_min, pitch_max)

	# --- 2. MOBILE MULTI-TOUCH CONTROLS ---
	elif event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
		else:
			touch_points.erase(event.index)

	elif event is InputEventScreenDrag:
		# Update current position for this touch index
		var previous_pos: Vector2 = touch_points.get(event.index, event.position - event.relative)
		touch_points[event.index] = event.position

		# Case A: Two fingers on screen -> Pinch-to-Zoom Gesture
		if touch_points.size() >= 2:
			var keys = touch_points.keys()
			var p1: Vector2 = touch_points[keys[0]]
			var p2: Vector2 = touch_points[keys[1]]
			var current_dist: float = p1.distance_to(p2)

			# Calculate previous distance based on the moved finger's previous position
			var prev_p1 := p1
			var prev_p2 := p2
			if event.index == keys[0]:
				prev_p1 = previous_pos
			elif event.index == keys[1]:
				prev_p2 = previous_pos

			var prev_dist: float = prev_p1.distance_to(prev_p2)
			var pinch_delta: float = current_dist - prev_dist

			# Spreading fingers apart (pinch_delta > 0) -> Zoom In (distance decreases)
			# Pinching fingers together (pinch_delta < 0) -> Zoom Out (distance increases)
			target_distance = clampf(target_distance - (pinch_delta * pinch_zoom_sensitivity), min_distance, max_distance)

		# Case B: Exactly one finger drag -> Orbit rotation
		elif touch_points.size() <= 1:
			target_yaw -= event.relative.x * orbit_speed
			target_pitch = clampf(target_pitch - event.relative.y * (orbit_speed * 50.0), pitch_min, pitch_max)

func _process(delta: float) -> void:
	rotation.y = lerp_angle(rotation.y, target_yaw, delta * smooth_factor)
	pitch_pivot.rotation_degrees.x = lerpf(pitch_pivot.rotation_degrees.x, target_pitch, delta * smooth_factor)

	current_distance = lerpf(current_distance, target_distance, delta * smooth_factor)
	camera.position.z = current_distance
