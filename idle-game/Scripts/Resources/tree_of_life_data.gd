class_name TreeOfLifeData
extends Resource

@export_group("Identification")
@export var id: String = "tree_of_life"
@export var display_name: String = "Tree of Life"
@export_multiline var description: String = ""
@export var icon: Texture2D

@export_group("Active Economy (Click)")
## Cost to upgrade the Tree of Life to the next level
@export var base_cost: float = 10.0
## Cost multiplier per level
@export var cost_multiplier: float = 1.20
## Base click power at level 1
@export var base_click_power: float = 1.0
## Additional click power added for each level above 1
@export var click_power_per_level: float = 1.0

@export_group("Visual 3D")
@export var model_scene: PackedScene

## Calculates upgrade cost for the given level
func get_cost_for_level(current_level: int) -> float:
	return base_cost * pow(cost_multiplier, current_level)

## Calculates total click power based on current tree level
func get_click_power(current_level: int) -> float:
	if current_level <= 1:
		return base_click_power
	return base_click_power + (click_power_per_level * (current_level - 1))
