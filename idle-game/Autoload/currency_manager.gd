extends Node

## Signals for UI to react to any change without polling
signal vitality_changed(new_amount: float)
signal rates_updated(passive_rate: float, click_value: float)

## Main currency
var vitality: float = 0.0

## Calculated rates
var vitality_per_second: float = 0.0
var vitality_per_click: float = 0.0

## Add vitality (per click or passive gen)
func add_vitality (amount: float) -> void:
	if amount <= 0.0:
		return
	vitality += amount
	vitality_changed.emit(vitality)
	
## Spend vitality. Return false if the funds are insufficient
func spend_vitality(amount: float) -> bool:
	if vitality >= amount:
		vitality -= amount
		vitality_changed.emit(vitality)
		return true
	return false

## Updates the rates abd emmits the signal so the HUD can upadate its labels of "+X/s" and "+X/tap"
func set_rates(new_passive: float, new_clikc: float) -> void:
	vitality_per_second = new_passive
	vitality_per_click = new_clikc
	rates_updated.emit(vitality_per_second, vitality_per_click)
	
## Formats numbers in idle notation: 1.5 K, 2.3 M, 10.0 B
func format_number(value:float) -> String:
	if value < 1000.0:
		return str(int(value))
	var suffixes: Array[String] = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
	var suffix_index: int = 0
	var temp: float = value
	
	while temp >= 1000.0 and suffix_index < suffixes.size() - 1:
		temp /= 1000.0
		suffix_index +=1
		
	return "%.2f %s" % [temp, suffixes[suffix_index]]
