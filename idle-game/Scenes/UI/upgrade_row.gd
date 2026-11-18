extends PanelContainer

signal buy_requested(item_id: String)

@onready var icon_rect: TextureRect = %IconRect
@onready var name_label: Label = %NameLabel
@onready var level_label: Label = %LevelLabel
@onready var cost_label: Label = %CostLabel
@onready var buy_button: Button = %BuyButton

var item_id: String = ""

func _ready() -> void:
	buy_button.pressed.connect(func(): buy_requested.emit(item_id))

func setup(p_id: String, p_name: String, p_level_text: String, p_cost_text: String, p_icon: Texture2D, can_afford: bool) -> void:
	item_id = p_id
	name_label.text = p_name
	level_label.text = p_level_text
	cost_label.text = p_cost_text
	if p_icon:
		icon_rect.texture = p_icon
	buy_button.disabled = not can_afford
