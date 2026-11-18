extends Node

## Signals for UI to react to any change without polling
signal vitality_changed(new_amount: float)
signal rates_updated(passive_rate: float, click_value: float)

## Main currency
var vitality: float = 0.0

## Calculated rates
var vitality_per_second: float = 0.0
var vitality_per_click: float = 1.0

## UI Update Throttling (Limits continuous passive updates to 10 Hz for mobile CPU optimization)
const UI_UPDATE_INTERVAL: float = 0.1
var _ui_update_timer: float = 0.0
var _has_unemitted_passive_vitality: bool = false

func _process(delta: float) -> void:
	if _has_unemitted_passive_vitality:
		_ui_update_timer += delta
		if _ui_update_timer >= UI_UPDATE_INTERVAL:
			_ui_update_timer = 0.0
			_has_unemitted_passive_vitality = false
			vitality_changed.emit(vitality)

## Add vitality. Pass force_emit = true for instant actions (clicks/rewards), false for continuous passive ticks
func add_vitality(amount: float, force_emit: bool = false) -> void:
	if amount <= 0.0:
		return
	vitality += amount
	if force_emit:
		_has_unemitted_passive_vitality = false
		_ui_update_timer = 0.0
		vitality_changed.emit(vitality)
	else:
		_has_unemitted_passive_vitality = true

## Spend vitality. Returns false if the funds are insufficient
func spend_vitality(amount: float) -> bool:
	if vitality >= amount:
		vitality -= amount
		_has_unemitted_passive_vitality = false
		_ui_update_timer = 0.0
		vitality_changed.emit(vitality)
		return true
	return false

## Updates the rates and emits the signal so the HUD can update its labels of "+X/s" and "+X/tap"
func set_rates(new_passive: float, new_click: float) -> void:
	vitality_per_second = new_passive
	vitality_per_click = new_click
	rates_updated.emit(vitality_per_second, vitality_per_click)

## Formats numbers in idle notation: 1.5 K, 2.3 M, 10.0 B
func format_number(value: float) -> String:
	if value < 1000.0:
		return str(int(value))
	var suffixes: Array[String] = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
	var suffix_index: int = 0
	var temp: float = value

	while temp >= 1000.0 and suffix_index < suffixes.size() - 1:
		temp /= 1000.0
		suffix_index += 1

	return "%.2f %s" % [temp, suffixes[suffix_index]]
