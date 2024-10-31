class_name DifficultyResource
extends Resource

enum Level {
	INTERN,
	JUNIOR,
	SENIOR,
	MANAGER,
}

@export var level := Level.JUNIOR
@export var min_documents := 1.0
@export var max_documents := 1.0
@export var distractions := 0.0
@export var bgm_speed := 1.0
@export var min_performance := 0
