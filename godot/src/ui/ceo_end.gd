extends Control

@export var retry_btn: TypingButton
@export var break_btn: TypingButton

@export_category("Player")
@export var player_total: Label
@export var player_combo: Label
@export var player_wrong: Label
@export var player_points: Label

@export_category("Boss")
@export var boss_total: Label
@export var boss_combo: Label
@export var boss_wrong: Label
@export var boss_points: Label

@export var open_sound: AudioStreamPlayer
@onready var day_delegator: Delegator = $DayDelegator
@onready var end_effect: EffectRoot = $EndEffect
@onready var end_container: CenterContainer = $EndContainer

func _ready() -> void:
	hide()
	
	retry_btn.finished.connect(func(): GameManager.start())
	break_btn.finished.connect(func(): GameManager.back_to_menu())

func open(data: Dictionary, boss_data: Dictionary):
	end_container.show()
	end_effect.do_effect()
	show()
	open_sound.play()
	
	player_total.text = "Tasks %s" % data["total"]
	player_combo.text = "%sx" % data["combo"]
	player_wrong.text = "Wrong %s" % data["wrong"]
	
	boss_total.text = boss_data["total"]
	boss_combo.text = "%sx" % boss_data["combo"]
	boss_wrong.text = boss_data["wrong"]

func _unhandled_input(event: InputEvent) -> void:
	if end_container.visible:
		day_delegator.handle_event(event)
