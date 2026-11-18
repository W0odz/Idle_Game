extends Control

@onready var vitality_label: Label = %VitalityLabel
@onready var bottom_sheet: PanelContainer = %BottomSheet
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

func _ready() -> void:
	CurrencyManager.vitality_changed.connect(_on_vitality_changed)
	CurrencyManager.rates_updated.connect(_on_rates_updated)

	tab_tree_btn.pressed.connect(func(): set_tab(Tab.TREE))
	tab_flora_btn.pressed.connect(func(): set_tab(Tab.FLORA))
	tab_dino_btn.pressed.connect(func(): set_tab(Tab.DINO))
	close_sheet_btn.pressed.connect(func(): set_tab(Tab.NONE))

	update_vitality_display()
	set_tab(Tab.NONE)

func update_vitality_display() -> void:
	vitality_label.text = CurrencyManager.format_number(CurrencyManager.vitality)

func set_tab(tab: Tab) -> void:
	current_tab = tab
	if current_tab == Tab.NONE:
		bottom_sheet.visible = false
		close_sheet_btn.visible = false
	else:
		bottom_sheet.visible = true
		close_sheet_btn.visible = true
		refresh_items()

func refresh_items() -> void:
	for child in items_container.get_children():
		child.queue_free()

	var current_vitality := CurrencyManager.vitality

	match current_tab:
		Tab.TREE:
			var tree_data = GameManager.get("tree_data")
			var level: int = GameManager.get("tree_level") if GameManager.get("tree_level") != null else 1
			var cost: float = 10.0 * pow(1.2, level - 1)
			var display_title: String = "ÁRVORE DA VIDA"

			if tree_data:
				cost = tree_data.get_cost_for_level(level)
				if not tree_data.display_name.is_empty():
					display_title = tree_data.display_name.to_upper()

			var can_afford := (current_vitality >= cost)
			var row = UPGRADE_ROW_SCENE.instantiate()
			items_container.add_child(row)
			row.setup(
				"tree_of_life",
				display_title,
				"Nível %d" % level,
				CurrencyManager.format_number(cost),
				ICON_TREE,
				can_afford
			)
			row.buy_requested.connect(_on_tree_upgrade_bought)

		Tab.FLORA:
			for flora_id in GameManager.flora_catalog:
				var data: FloraData = GameManager.flora_catalog[flora_id]
				var lvl: int = GameManager.owned_flora.get(flora_id, 0)
				var cost := data.get_cost_for_level(lvl)
				var can_afford := (current_vitality >= cost)
				var row = UPGRADE_ROW_SCENE.instantiate()
				items_container.add_child(row)
				row.setup(
					flora_id,
					data.display_name.to_upper(),
					"Nível %d" % lvl,
					CurrencyManager.format_number(cost),
					ICON_LEAF,
					can_afford
				)
				row.buy_requested.connect(func(id): GameManager.buy_flora(id))

		Tab.DINO:
			for dino_id in GameManager.dino_catalog:
				var data: DinoData = GameManager.dino_catalog[dino_id]
				var count: int = GameManager.owned_dinos.get(dino_id, 0)
				var cost := data.get_cost_for_next(count)
				var can_afford := (current_vitality >= cost)
				var row = UPGRADE_ROW_SCENE.instantiate()
				items_container.add_child(row)
				row.setup(
					dino_id,
					data.common_name.to_upper(),
					"Qtd. %d" % count,
					CurrencyManager.format_number(cost),
					ICON_FOOTPRINT,
					can_afford
				)
				row.buy_requested.connect(func(id): GameManager.buy_dino(id))

func _on_tree_upgrade_bought(_id: String) -> void:
	if GameManager.has_method("buy_tree_upgrade"):
		GameManager.buy_tree_upgrade()
	else:
		var level: int = GameManager.get("tree_level") if GameManager.get("tree_level") != null else 1
		var cost: float = 10.0 * pow(1.2, level - 1)
		if CurrencyManager.spend_vitality(cost):
			GameManager.set("tree_level", level + 1)
			GameManager.recalculate_economy()
	refresh_items()

func _on_vitality_changed(_new_amount: float) -> void:
	update_vitality_display()
	if current_tab != Tab.NONE:
		refresh_items()

func _on_rates_updated(_passive: float, _click: float) -> void:
	update_vitality_display()
