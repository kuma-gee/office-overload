class_name SpillMug
extends Node2D

@onready var stain_area: Area2D = $StainArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var spill_stain: Sprite2D = $SpillStain
@onready var lifetime: Timer = $Lifetime

@onready var orig_pos = position
@onready var hide_pos = orig_pos + Vector2(-1, -0.5) * 40

var tw: Tween
var active = false

func _ready() -> void:
	position = hide_pos
	
	stain_area.monitoring = false
	stain_area.area_entered.connect(func(a): a.stained.emit())
	lifetime.timeout.connect(func(): hide_spill())
	
func hide_spill():
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(spill_stain, "modulate", Color.TRANSPARENT, 2.0).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func(): animation_player.play("RESET"))
	tw.tween_property(self, "position", hide_pos, 0.5)
	tw.tween_callback(func(): active = false)

func spill():
	active = true
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "position", orig_pos, 0.5)
	await tw.finished
	animation_player.play("spill")
	
	var time = lifetime.wait_time * GameManager.get_distraction_reduction()
	lifetime.start(time)
