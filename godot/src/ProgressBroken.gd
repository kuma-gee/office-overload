extends TextureRect

@onready var burst_particles = $BurstParticles
@onready var shard_particles = $ShardParticles
@onready var break_sound = $BreakSound

func _ready():
	hide()

func play():
	show()
	burst_particles.emitting = true
	shard_particles.emitting = true
	break_sound.play()
