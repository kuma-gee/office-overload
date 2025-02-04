class_name DeskItem
extends Node2D

@onready var orig_pos := position

var tw: Tween

func _ready() -> void:
	position.y = 150

func move_in(delay = 0.2):
	if GameManager.is_motion:
		await get_tree().create_timer(delay).timeout
	
	tw = _create_tw()
	tw.tween_property(self, "position", orig_pos, 0.5)
	if not GameManager.is_motion:
		tw.set_speed_scale(1000.)
	
	SoundManager.play_folder_slide()

func move_open():
	tw = _create_tw()
	tw.tween_property(self, "position", orig_pos + Vector2.DOWN * 100, 0.5)
	
	if not GameManager.is_motion:
		tw.set_speed_scale(1000.)
	
	SoundManager.play_folder_slide()
	await get_tree().create_timer(0.2).timeout

func _create_tw():
	if tw and tw.is_running():
		tw.kill()
	
	return create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
