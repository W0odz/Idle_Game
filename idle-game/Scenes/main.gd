extends Node3D

@onready var flora_container: Node3D = $FloraContainer
@onready var dino_container: Node3D = $DinoContainer

func _ready() -> void:
	GameManager.dino_spawned.connect(_on_dino_spawned)
	GameManager.flora_upgraded.connect(_on_flora_upgraded)

func _on_dino_spawned(dino_data: DinoData, _total_owned: int) -> void:
	if not dino_data.model_scene:
		return

	var dino_instance: Node3D = dino_data.model_scene.instantiate()
	# Spawn at a random position on the island
	var angle := randf() * TAU
	var dist := randf_range(3.0, 5.5)
	dino_instance.position = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
	dino_container.add_child(dino_instance)

func _on_flora_upgraded(flora_data: FloraData, current_level: int) -> void:
	if not flora_data.model_scene:
		return

	# Only instantiate a physical bush up to 8 visual bushes on the island
	if current_level <= 8:
		var flora_instance: Node3D = flora_data.model_scene.instantiate()
		var angle := (current_level / 8.0) * TAU + randf_range(-0.15, 0.15)
		var dist := randf_range(2.0, 3.2)
		flora_instance.position = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		flora_instance.scale = Vector3.ONE * randf_range(0.85, 1.15)
		flora_container.add_child(flora_instance)
