extends Control

@onready var vitality_label: Label = %VitalityLabel
@onready var rate_label: Label = %RateLabel
@onready var bottom_sheet: PanelContainer = %BottomSheet
@onready var handle_area: Control = %HandleArea
@onready var items_container: VBoxContainer = %ItemsContainer

@onready var tab_tree_btn: Button = %TabTreeBtn
@onready var tab_flora_btn: Button = %TabFloraBtn
@onready var tab_dino_btn: Button = %TabDinoBtn
@onready var close_sheet_btn: Button = %CloseSheetBtn

const UPGRADE_ROW_SCENE = preload("res://Scenes/UI/UpgradeRow.tscn")
const ICON_TREE = preload("res://Assets/UI/Icons/icon_tree.svg")
const ICON_LEAF = preload("res://Assets/UI/Icons/icon_leaf.svg")
const ICON_FOOTPRINT = preload("res://Assets/UI/Icons/icon_footprint.svg")

enum Tab { NONE, TREE, FLORA, DINO }
var current_tab: Tab = Tab.NONE

var active_rows: Dictionary = {}
var recent_tap_times: Array[float] = []

# Vertical Y coordinates of bottom_sheet.position.y:
# In an 800px high viewport:
# 1. POS_CLOSED = 800.0 (completely offscreen below the bottom bar)
# 2. POS_MID = 420.0 (open halfway, diorama visible above)
# 3. POS_FULL = 76.0 (full screen, just beneath the top bar)
const POS_CLOSED: float = 800.0
const POS_MID: float = 420.0
const POS_FULL: float = 76.0

var is_dragging_sheet: bool = false
var drag_start_mouse_y: float = 0.0
var drag_start_sheet_y: float = 0.0
var active_tween: Tween = null

const COLOR_ACTIVE: Color = Color(0.45, 0.88, 0.42, 1.0)
const COLOR_INACTIVE: Color = Color(1.0, 1.0, 1.0, 1.0)

func _ready() -> void:
	CurrencyManager.vitality_changed.connect(_on_vitality_changed)
	CurrencyManager.rates_updated.connect(_on_rates_updated)
	GameManager.player_tapped.connect(func(_amount): record_player_tap())

	tab_tree_btn.pressed.connect(func(): on_tab_button_pressed(Tab.TREE))
	tab_flora_btn.pressed.connect(func(): on_tab_button_pressed(Tab.FLORA))
	tab_dino_btn.pressed.connect(func(): on_tab_button_pressed(Tab.DINO))
	close_sheet_btn.pressed.connect(func(): close_sheet())

	handle_area.gui_input.connect(_on_handle_gui_input)

	update_vitality_display()
	update_tab_icons_color()
	bottom_sheet.position.y = POS_CLOSED
	bottom_sheet.visible = false

func _process(delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	while not recent_tap_times.is_empty() and (now - recent_tap_times[0]) > 1.5:
		recent_tap_times.pop_front()

	update_vitality_display()

func record_player_tap() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	recent_tap_times.append(now)
	update_vitality_display()

func update_vitality_display() -> void:
	vitality_label.text = CurrencyManager.format_number(CurrencyManager.vitality)

	var tap_rate: float = 0.0
	if not recent_tap_times.is_empty():
		tap_rate = float(recent_tap_times.size()) / 1.5

	var click_vitality_per_sec: float = tap_rate * CurrencyManager.vitality_per_click
	var combined_rate: float = CurrencyManager.vitality_per_second + click_vitality_per_sec

	rate_label.text = "+%s/s" % CurrencyManager.format_number(combined_rate)

func on_tab_button_pressed(tab: Tab) -> void:
	if current_tab == tab and bottom_sheet.visible:
		# Clicking the already selected tab toggles it closed
		close_sheet()
		return

	# Switching to a different tab keeps the sheet open at its current height!
	current_tab = tab
	bottom_sheet.visible = true
	close_sheet_btn.visible = true
	update_tab_icons_color()
	build_items()

	# Only animate if opening from closed state
	if bottom_sheet.position.y > POS_MID + 30.0:
		snap_sheet_to(POS_MID, true)

func close_sheet() -> void:
	current_tab = Tab.NONE
	update_tab_icons_color()
	close_sheet_btn.visible = false
	snap_sheet_to(POS_CLOSED, true, func():
		bottom_sheet.visible = false
	)

func update_tab_icons_color() -> void:
	tab_tree_btn.modulate = COLOR_ACTIVE if current_tab == Tab.TREE else COLOR_INACTIVE
	tab_flora_btn.modulate = COLOR_ACTIVE if current_tab == Tab.FLORA else COLOR_INACTIVE
	tab_dino_btn.modulate = COLOR_ACTIVE if current_tab == Tab.DINO else COLOR_INACTIVE

func _on_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging_sheet = true
			drag_start_mouse_y = event.global_position.y
			drag_start_sheet_y = bottom_sheet.position.y
			if active_tween and active_tween.is_valid():
				active_tween.kill()
		else:
			if is_dragging_sheet:
				is_dragging_sheet = false
				finalize_drag_snap()

	elif event is InputEventMouseMotion and is_dragging_sheet:
		var delta_y: float = event.global_position.y - drag_start_mouse_y
		var new_y: float = drag_start_sheet_y + delta_y
		bottom_sheet.position.y = clampf(new_y, POS_FULL, POS_CLOSED)

	elif event is InputEventScreenDrag and is_dragging_sheet:
		var delta_y: float = event.relative.y
		var new_y: float = bottom_sheet.position.y + delta_y
		bottom_sheet.position.y = clampf(new_y, POS_FULL, POS_CLOSED)

func finalize_drag_snap() -> void:
	var current_y: float = bottom_sheet.position.y

	var close_threshold: float = (POS_MID + POS_CLOSED) / 2.0
	var expand_threshold: float = (POS_MID + POS_FULL) / 2.0

	if current_y > close_threshold:
		close_sheet()
	elif current_y < expand_threshold:
		snap_sheet_to(POS_FULL, true)
	else:
		snap_sheet_to(POS_MID, true)

func snap_sheet_to(target_y: float, animate: bool = true, on_complete: Callable = Callable()) -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()

	if not animate:
		bottom_sheet.position.y = target_y
		if on_complete.is_valid():
			on_complete.call()
		return

	active_tween = create_tween()
	active_tween.tween_property(bottom_sheet, "position:y", target_y, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if on_complete.is_valid():
		active_tween.tween_callback(on_complete)

func build_items() -> void:
	for child in items_container.get_children():
		child.queue_free()
	active_rows.clear()

	var current_vitality := CurrencyManager.vitality
	var current_tree_level: int = GameManager.get("tree_level") if GameManager.get("tree_level") != null else 1

	match current_tab:
		Tab.TREE:
			var tree_data = GameManager.get("tree_data")
			var cost: float = 10.0 * pow(1.2, current_tree_level - 1)
			var display_title: String = "ÁRVORE DA VIDA"
			var click_power: float = 1.0

			if tree_data:
				cost = tree_data.get_cost_for_level(current_tree_level)
				click_power = tree_data.get_click_power(current_tree_level)
				if not tree_data.display_name.is_empty():
					display_title = tree_data.display_name.to_upper()

			var can_afford := (current_vitality >= cost)
			var benefit_text := "+1.00 por toque (Atual: +%s)" % CurrencyManager.format_number(click_power)

			var row = UPGRADE_ROW_SCENE.instantiate()
			items_container.add_child(row)
			active_rows["tree_of_life"] = row
			row.setup(
				"tree_of_life",
				display_title,
				"Nível %d" % current_tree_level,
				CurrencyManager.format_number(cost),
				benefit_text,
				ICON_TREE,
				can_afford,
				true,
				"Aumenta o limite de evolução de todos os seres"
			)
			row.buy_requested.connect(_on_tree_upgrade_bought)

		Tab.FLORA:
			for flora_id in GameManager.flora_catalog:
				var data: FloraData = GameManager.flora_catalog[flora_id]
				var lvl: int = GameManager.owned_flora.get(flora_id, 0)
				var cost := data.get_cost_for_level(lvl)
				var can_afford := (current_vitality >= cost)

				var req_tree_lvl: int = data.get("required_tree_level") if data.get("required_tree_level") != null else 1
				var is_unlocked: bool = (current_tree_level >= req_tree_lvl)
				var is_capped: bool = (lvl >= current_tree_level)

				var hint := ""
				if not is_unlocked:
					hint = "🔒 Requer Árvore Nível %d" % req_tree_lvl
				elif is_capped:
					hint = "⛔ Limite atingido! Evolua a Árvore para continuar"
					is_unlocked = false
				else:
					hint = "Limite atual: Nv. %d / %d" % [lvl, current_tree_level]

				var current_prod := data.get_total_production(lvl)
				var next_gain := data.passive_vitality_per_sec
				var benefit_text := "+%s/s (Atual: +%s/s)" % [
					CurrencyManager.format_number(next_gain),
					CurrencyManager.format_number(current_prod)
				]

				var row = UPGRADE_ROW_SCENE.instantiate()
				items_container.add_child(row)
				active_rows[flora_id] = row
				row.setup(
					flora_id,
					data.display_name.to_upper(),
					"Nível %d" % lvl,
					CurrencyManager.format_number(cost),
					benefit_text,
					ICON_LEAF,
					can_afford,
					is_unlocked,
					hint
				)
				row.buy_requested.connect(func(id):
					if GameManager.buy_flora(id):
						build_items()
				)

		Tab.DINO:
			for dino_id in GameManager.dino_catalog:
				var data: DinoData = GameManager.dino_catalog[dino_id]
				var count: int = GameManager.owned_dinos.get(dino_id, 0)
				var cost := data.get_cost_for_next(count)
				var can_afford := (current_vitality >= cost)

				var req_tree_lvl: int = data.get("required_tree_level") if data.get("required_tree_level") != null else 1
				var tree_ok: bool = (current_tree_level >= req_tree_lvl)

				var req_flora_id: String = data.get("required_flora_id") if data.get("required_flora_id") != null else ""
				var req_flora_lvl: int = data.get("required_flora_level") if data.get("required_flora_level") != null else 1
				var flora_ok: bool = true
				if not req_flora_id.is_empty():
					var owned_lvl: int = GameManager.owned_flora.get(req_flora_id, 0)
					flora_ok = (owned_lvl >= req_flora_lvl)

				var is_capped: bool = (count >= current_tree_level)
				var is_unlocked: bool = tree_ok and flora_ok
				var hint := ""

				if not tree_ok:
					hint = "🔒 Requer Árvore Nível %d" % req_tree_lvl
				elif not flora_ok:
					var flora_name := req_flora_id
					if GameManager.flora_catalog.has(req_flora_id):
						flora_name = GameManager.flora_catalog[req_flora_id].display_name
					hint = "🔒 Requer %s Nível %d" % [flora_name, req_flora_lvl]
				elif is_capped:
					hint = "⛔ Limite atingido! Evolua a Árvore para continuar"
					is_unlocked = false
				else:
					hint = "Limite atual: %d / %d" % [count, current_tree_level]

				var bonus_pct := int(data.bonus_multiplier_per_unit * 100.0)
				var current_pct := int(data.get_total_bonus(count) * 100.0)
				var benefit_text := "+%d%% bônus global (Total: +%d%%)" % [bonus_pct, current_pct]

				var row = UPGRADE_ROW_SCENE.instantiate()
				items_container.add_child(row)
				active_rows[dino_id] = row
				row.setup(
					dino_id,
					data.common_name.to_upper(),
					"Qtd. %d" % count,
					CurrencyManager.format_number(cost),
					benefit_text,
					ICON_FOOTPRINT,
					can_afford,
					is_unlocked,
					hint
				)
				row.buy_requested.connect(func(id):
					if GameManager.buy_dino(id):
						build_items()
				)

func update_rows_state() -> void:
	var current_vitality := CurrencyManager.vitality
	var current_tree_level: int = GameManager.get("tree_level") if GameManager.get("tree_level") != null else 1

	match current_tab:
		Tab.TREE:
			if active_rows.has("tree_of_life") and is_instance_valid(active_rows["tree_of_life"]):
				var tree_data = GameManager.get("tree_data")
				var cost: float = 10.0 * pow(1.2, current_tree_level - 1)
				if tree_data:
					cost = tree_data.get_cost_for_level(current_tree_level)
				var can_afford := (current_vitality >= cost)
				active_rows["tree_of_life"].update_state(can_afford, true)

		Tab.FLORA:
			for flora_id in active_rows:
				var row = active_rows[flora_id]
				if not is_instance_valid(row) or not GameManager.flora_catalog.has(flora_id):
					continue
				var data: FloraData = GameManager.flora_catalog[flora_id]
				var lvl: int = GameManager.owned_flora.get(flora_id, 0)
				var cost := data.get_cost_for_level(lvl)
				var can_afford := (current_vitality >= cost)

				var req_tree_lvl: int = data.get("required_tree_level") if data.get("required_tree_level") != null else 1
				var is_unlocked: bool = (current_tree_level >= req_tree_lvl) and (lvl < current_tree_level)
				row.update_state(can_afford, is_unlocked)

		Tab.DINO:
			for dino_id in active_rows:
				var row = active_rows[dino_id]
				if not is_instance_valid(row) or not GameManager.dino_catalog.has(dino_id):
					continue
				var data: DinoData = GameManager.dino_catalog[dino_id]
				var count: int = GameManager.owned_dinos.get(dino_id, 0)
				var cost := data.get_cost_for_next(count)
				var can_afford := (current_vitality >= cost)

				var req_tree_lvl: int = data.get("required_tree_level") if data.get("required_tree_level") != null else 1
				var tree_ok: bool = (current_tree_level >= req_tree_lvl)

				var req_flora_id: String = data.get("required_flora_id") if data.get("required_flora_id") != null else ""
				var req_flora_lvl: int = data.get("required_flora_level") if data.get("required_flora_level") != null else 1
				var flora_ok: bool = true
				if not req_flora_id.is_empty():
					var owned_lvl: int = GameManager.owned_flora.get(req_flora_id, 0)
					flora_ok = (owned_lvl >= req_flora_lvl)

				var is_capped: bool = (count >= current_tree_level)
				var is_unlocked: bool = tree_ok and flora_ok and not is_capped
				row.update_state(can_afford, is_unlocked)

func _on_tree_upgrade_bought(_id: String) -> void:
	if GameManager.has_method("buy_tree_upgrade"):
		GameManager.buy_tree_upgrade()
	else:
		var level: int = GameManager.get("tree_level") if GameManager.get("tree_level") != null else 1
		var cost: float = 10.0 * pow(1.2, level - 1)
		if CurrencyManager.spend_vitality(cost):
			GameManager.set("tree_level", level + 1)
			GameManager.recalculate_economy()
	build_items()

func _on_vitality_changed(_new_amount: float) -> void:
	update_vitality_display()
	if current_tab != Tab.NONE:
		update_rows_state()

func _on_rates_updated(_passive: float, _click: float) -> void:
	update_vitality_display()
