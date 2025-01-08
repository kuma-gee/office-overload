class_name DifficultyResource
extends Resource

enum Level {
	INTERN,
	JUNIOR,
	SENIOR,
	MANAGER,
	CEO,
}

@export var level := Level.INTERN
@export var bgm_speed := 1.0
@export var money_multiplier := 0.0
@export var max_performance := 0

@export_category("Difficulty")
@export var base_document_time := 1.0
@export var distractions := 0.0
@export var invalid_word_chance := 0.0

@export_category("Words")
@export var easy_words := 0.0
@export var medium_words := 0.0
@export var hard_words := 0.0
