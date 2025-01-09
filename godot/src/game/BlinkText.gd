extends Label

@export var blink_timer: Timer
@export var blink_duration := 0.7

func _ready():
	blink_timer.start()
	blink_timer.timeout.connect(func():
		modulate = Color.TRANSPARENT
		await get_tree().create_timer(blink_duration).timeout
		modulate = Color.WHITE
		blink_timer.start()
	)
