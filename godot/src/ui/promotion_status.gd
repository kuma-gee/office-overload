class_name PromotionStatus
extends PanelContainer

@export var promotion_text: RichTextLabel
@export var promotion_sound: AudioStreamPlayer
@onready var end_effect: EffectRoot = $EndEffect

@onready var original_pos := global_position
@onready var hide_pos := original_pos + Vector2(-0.2, 1) * 150

var tw: Tween

func _ready() -> void:
	hide()

func open():
	promotion_text.word = GameManager.get_level_text()
	promotion_text.focused = true
	
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(self, "global_position", original_pos, 1.0).from(hide_pos)
	show()
	
	promotion_sound.play()
