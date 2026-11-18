extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _on_click_area_input_event(_camera: Camera3D, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		play_click_feedback()
		GameManager.perform_click()

func play_click_feedback() -> void:
	if animation_player and animation_player.has_animation("bounce"):
		animation_player.stop()
		animation_player.play("bounce")
