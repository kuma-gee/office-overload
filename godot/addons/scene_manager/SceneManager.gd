extends Node2D

signal fade_complete
signal transition_finished

@onready var _tree := get_tree()
@onready var _animation_player : AnimationPlayer = $AnimationPlayer

func change_scene(path: Variant) -> void:
	await fade_out()
	if path == null:
		_tree.reload_current_scene()
	else:
		_tree.change_scene_to_file(path)
	await _tree.create_timer(0.5).timeout
	await fade_in()

func reload_scene() -> void:
	await change_scene(null)

func fade_out() -> void:
	_animation_player.play("ShaderFade")
	await _animation_player.animation_finished
	fade_complete.emit()

func fade_in() -> void:
	_animation_player.play_backwards("ShaderFade")
	await _animation_player.animation_finished
	transition_finished.emit()
