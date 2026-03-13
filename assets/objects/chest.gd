extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area: Area2D = $Area2D

var player_in_range: bool = false
const INTERACT_RADIUS := 34.0
var is_open: bool = false
var main_ref: Node = null
var world_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	if world_pos == Vector2.ZERO:
		world_pos = global_position
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.scale = Vector2(1.2, 1.2)
	sprite.position = Vector2(0, -6)
	if is_open:
		sprite.play("opened")
	else:
		sprite.play("closed")

func _process(_delta: float) -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	player_in_range = player != null and global_position.distance_to(player.global_position) <= INTERACT_RADIUS
	if player_in_range and Input.is_action_just_pressed("interact"):
		try_interact()

func setup_for_world(main_node: Node, tile_world_pos: Vector2, opened: bool) -> void:
	main_ref = main_node
	world_pos = tile_world_pos
	global_position = tile_world_pos
	set_open_state(opened)

func set_open_state(opened: bool) -> void:
	is_open = opened
	if not is_inside_tree():
		return
	if is_open:
		sprite.play("opened")
	else:
		sprite.play("closed")

func try_interact() -> void:
	if is_open:
		return
	if main_ref != null and main_ref.has_method("try_open_chest_at_world"):
		if main_ref.try_open_chest_at_world(world_pos):
			return
	open_chest()

func open_chest() -> void:
	if is_open:
		return
	is_open = true
	sprite.play("opening")

func _on_animation_finished() -> void:
	if sprite.animation == "opening":
		sprite.play("opened")

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false
