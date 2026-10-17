class_name FloraData
extends Resource

@export_group("Identification")
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D

@export_group("Click Economy")
## Planting or upgrading cost for this element
@export var base_cost: float = 15
@export var cost_multiplier: float = 1.10
## How much aditional vitality each level of this element generate per click
@export var click_power_per_level: float = 1.0

@export_group("Visual 3D")
@export var model_scene: PackedScene

func get_cost_for_level(current_level: int) -> float:
	return base_cost * pow(cost_multiplier, current_level)

func get_total_click_bonus(current_level: int) -> float:
	return click_power_per_level * current_level
