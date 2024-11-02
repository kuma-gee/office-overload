extends ColorRect

@export var timer: Timer

func _ready() -> void:
	material = material.duplicate()

func _process(delta: float) -> void:
	if not timer or timer.is_stopped():
		_set_fill(0)
		return
	
	_set_fill(timer.time_left / timer.wait_time)

func _set_fill(v: float):
	var mat = material as ShaderMaterial
	mat.set_shader_parameter("fill", v)
