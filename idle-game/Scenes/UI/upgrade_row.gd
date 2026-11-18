extends PanelContainer

signal buy_requested(item_id: String)

@onready var icon_rect: TextureRect = %IconRect
@onready var badge_panel: PanelContainer = %BadgePanel
@onready var name_label: Label = %NameLabel
@onready var benefit_label: Label = %BenefitLabel
@onready var level_label: Label = %LevelLabel
@onready var condition_label: Label = %ConditionLabel
@onready var cost_label: Label = %CostLabel
@onready var drop_icon: TextureRect = %DropIcon
@onready var lock_icon: TextureRect = %LockIcon
@onready var buy_button: Button = %BuyButton
@onready var btn_content: HBoxContainer = %BtnContent

var item_id: String = ""

func _ready() -> void:
	btn_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drop_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	buy_button.button_down.connect(_on_button_down)

func _on_button_down() -> void:
	play_purchase_feedback()
	buy_requested.emit(item_id)

func play_purchase_feedback() -> void:
	buy_button.pivot_offset = buy_button.size / 2.0
	var tween = create_tween()
	tween.tween_property(buy_button, "scale", Vector2(0.92, 0.92), 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(buy_button, "scale", Vector2(1.05, 1.05), 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(buy_button, "scale", Vector2.ONE, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func setup(
	p_id: String,
	p_name: String,
	p_level_text: String,
	p_cost_text: String,
	p_benefit_text: String,
	p_icon: Texture2D,
	can_afford: bool,
	is_unlocked: bool,
	unlock_hint: String = ""
) -> void:
	item_id = p_id
	name_label.text = p_name
	level_label.text = p_level_text
	cost_label.text = p_cost_text
	benefit_label.text = p_benefit_text

	if p_icon:
		icon_rect.texture = p_icon

	if not unlock_hint.is_empty():
		condition_label.visible = true
		condition_label.text = unlock_hint
		if not is_unlocked:
			condition_label.modulate = Color(1.0, 0.7, 0.3)
		else:
			condition_label.modulate = Color(0.7, 0.9, 0.7)
	else:
		condition_label.visible = false

	update_state(can_afford, is_unlocked)

func update_state(can_afford: bool, is_unlocked: bool) -> void:
	var is_buyable: bool = is_unlocked and can_afford
	buy_button.disabled = not is_buyable

	if not is_unlocked:
		drop_icon.visible = false
		lock_icon.visible = true
		cost_label.modulate = Color(0.65, 0.65, 0.65, 1.0)
		badge_panel.modulate = Color(0.6, 0.6, 0.6, 1.0)
		name_label.modulate = Color(0.75, 0.75, 0.75, 1.0)
	else:
		drop_icon.visible = true
		lock_icon.visible = false
		badge_panel.modulate = Color.WHITE
		name_label.modulate = Color.WHITE
		if can_afford:
			cost_label.modulate = Color(0.12, 0.18, 0.12, 1.0)
		else:
			cost_label.modulate = Color(0.7, 0.7, 0.7, 0.8)
