extends VBoxContainer

@onready var promotion_yes = $HBoxContainer2/PromotionYes
@onready var promotion_no = $HBoxContainer2/PromotionNo

func _ready():
	update()
	visibility_changed.connect(func(): update())

func update():
	print(promotion_yes.word, ", ", promotion_no.word)
	promotion_yes.update()
	promotion_no.update()
