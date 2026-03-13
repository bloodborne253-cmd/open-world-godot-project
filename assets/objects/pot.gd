extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var main_ref: Node = null
var world_pos: Vector2 = Vector2.ZERO
var is_breaking: bool = false

func _ready() -> void:
	z_index = 6
	if world_pos == Vector2.ZERO:
		world_pos = global_position
	sprite.animation_finished.connect(_on_animation_finished)
	if not is_breaking:
		sprite.play("idle")

func setup_for_world(main_node: Node, tile_world_pos: Vector2) -> void:
	main_ref = main_node
	world_pos = tile_world_pos
	global_position = tile_world_pos
	if not is_breaking and is_inside_tree():
		sprite.play("idle")

func break_pot() -> void:
	if is_breaking:
		return
	is_breaking = true
	sprite.play("break")

func _on_animation_finished() -> void:
	if sprite.animation != &"break":
		return
	if main_ref != null and main_ref.has_method("on_pot_break_finished"):
		main_ref.on_pot_break_finished(world_pos, self)
	else:
		queue_free()
