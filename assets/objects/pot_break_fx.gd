extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	z_index = 8
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("break")

func _on_animation_finished() -> void:
	queue_free()
