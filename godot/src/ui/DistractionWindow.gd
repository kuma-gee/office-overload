extends PanelContainer

@export var label: TypedWord
@export var type := Distraction.Type.EMAIL

@export var slide_dir := Vector2.ZERO

@onready var start_pos := global_position

var tw: Tween
var mistakes := 0

func _ready():
	label.type_start.connect(func(): GameManager.start_type())
	label.type_finish.connect(func():
		GameManager.finish_type(label.word, mistakes)
		label.reset("")
		slide_out()
	)
	label.type_wrong.connect(func(): mistakes += 1)
	
	hide()

func set_word(w: String):
	label.word = w
	label.highlight_first = true
	slide_in()
	show()

func get_word():
	return label.word

func slide_in():
	if tw and tw.is_running():
		tw.kill()
	
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "global_position", start_pos, 0.5).from(start_pos - slide_dir.normalized() * (size.x if slide_dir.x != 0 else size.y))

func slide_out():
	if tw and tw.is_running():
		tw.kill()
	
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "global_position", start_pos - slide_dir.normalized() * (size.x if slide_dir.x != 0 else size.y), 0.5)

func get_label():
	return label
