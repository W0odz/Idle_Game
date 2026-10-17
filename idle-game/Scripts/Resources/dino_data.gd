class_name DinoData
extends Resource

@export_group("Identification")
@export var id: String = ""
@export var common_name: String = ""
@export var scientific_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D

@export_group("Passive Economy")
## Base cost to create the first iteration of this species
@export var base_cost: float = 10.0
## Cost multiplier to create more dinos from the same species
@export var cost_multiplier: float = 1.15
## Vitality/sec that each unit generates
@export var passive_vitality_per_sec: float = 5.0

@export_group("3D Visual")
@export var model_scene: PackedScene
@export var scale_factor: float = 1.0
@export_enum("ground", "flying", "water") var habitat: String = "ground"
@export var walk_speed: float = 2.0

func get_cost_for_next(current_count: int) -> float:
	return base_cost * pow(cost_multiplier, current_count)
	
func get_total_production(current_count: int ) -> float:
	return (passive_vitality_per_sec * current_count)
