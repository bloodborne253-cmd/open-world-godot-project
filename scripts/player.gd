extends Node2D
class_name Player

const SPEED := 260.0
const HITBOX_SIZE := Vector2(24, 24)
const ATTACK_TIME := 0.16
const ROLL_TIME := 0.18
const ROLL_COOLDOWN := 0.35
const ROLL_SPEED := 520.0
const SWORD_REACH := 34.0
const SWORD_THICK := 22.0
const SPRITE_SCALE := Vector2(2, 2)
const ANIMATION_FPS := 8.0
const ANIMATION_COLUMNS := 8
const ANIMATION_NAMES := [
	"idle_down",
	"idle_left_down",
	"idle_left_up",
	"idle_right_down",
	"idle_right_up",
	"idle_up",
	"walk_down",
	"walk_left_down",
	"walk_left_up",
	"walk_right_down",
	"walk_right_up",
	"walk_up",
]

var facing := "down"
var anim_facing := "down"
var attack_t := 0.0
var attack_applied := false
var roll_t := 0.0
var roll_cd := 0.0
var roll_dir := Vector2.ZERO
var last_move := Vector2.DOWN
var _side_vertical_hint := 1

@onready var animated_sprite: AnimatedSprite2D = _ensure_animated_sprite()

func _ready() -> void:
	_setup_sprite_animations()
	_update_animation(Vector2.ZERO)

func _process(delta: float) -> void:
	attack_t = max(attack_t - delta, 0.0)
	roll_t = max(roll_t - delta, 0.0)
	roll_cd = max(roll_cd - delta, 0.0)
	if attack_t == 0.0:
		attack_applied = false

func get_input_vector() -> Vector2:
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if v.length() > 1.0:
		v = v.normalized()
	return v

func update_facing(move: Vector2) -> void:
	if move == Vector2.ZERO:
		return
	last_move = move.normalized()
	if move.y < -0.01:
		_side_vertical_hint = -1
	elif move.y > 0.01:
		_side_vertical_hint = 1

	if absf(move.x) > absf(move.y):
		facing = "right" if move.x > 0.0 else "left"
	else:
		facing = "down" if move.y > 0.0 else "up"

	anim_facing = _animation_facing_from_move(last_move)

func try_start_attack() -> void:
	if attack_t <= 0.0:
		attack_t = ATTACK_TIME
		attack_applied = false

func try_start_roll(move: Vector2) -> void:
	if roll_t > 0.0 or roll_cd > 0.0:
		return
	if move == Vector2.ZERO:
		move = last_move
	if move == Vector2.ZERO:
		move = Vector2.DOWN
	roll_dir = move.normalized()
	roll_t = ROLL_TIME
	roll_cd = ROLL_COOLDOWN
	attack_t = 0.0
	attack_applied = false
	update_facing(roll_dir)
	_update_animation(roll_dir)

func movement_velocity() -> Vector2:
	if roll_t > 0.0:
		update_facing(roll_dir)
		_update_animation(roll_dir)
		return roll_dir * ROLL_SPEED
	var move := get_input_vector()
	update_facing(move)
	_update_animation(move)
	return move * SPEED

func sword_rect() -> Rect2:
	var center := global_position
	var pos := center
	var size := Vector2(SWORD_THICK + 20.0, SWORD_THICK + 20.0)
	match facing:
		"up":
			pos = center + Vector2(-SWORD_THICK * 0.5, -SWORD_REACH - 20.0)
			size = Vector2(SWORD_THICK, SWORD_THICK + 20.0)
		"down":
			pos = center + Vector2(-SWORD_THICK * 0.5, SWORD_REACH - 2.0)
			size = Vector2(SWORD_THICK, SWORD_THICK + 20.0)
		"left":
			pos = center + Vector2(-SWORD_REACH - 20.0, -SWORD_THICK * 0.5)
			size = Vector2(SWORD_THICK + 20.0, SWORD_THICK)
		"right":
			pos = center + Vector2(SWORD_REACH - 2.0, -SWORD_THICK * 0.5)
			size = Vector2(SWORD_THICK + 20.0, SWORD_THICK)
	return Rect2(pos, size)

func _ensure_animated_sprite() -> AnimatedSprite2D:
	var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		sprite = AnimatedSprite2D.new()
		sprite.name = "AnimatedSprite2D"
		add_child(sprite)
		sprite.owner = self if self.scene_file_path != "" else null
	sprite.scale = SPRITE_SCALE
	sprite.centered = true
	sprite.position = Vector2.ZERO
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return sprite

func _setup_sprite_animations() -> void:
	var frames := SpriteFrames.new()
	for animation_name in ANIMATION_NAMES:
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, ANIMATION_FPS)
		frames.set_animation_loop(animation_name, true)
		var texture: Texture2D = load("res://assets/sprites/player/%s.png" % animation_name)
		if texture == null:
			push_warning("Missing player animation: %s" % animation_name)
			continue
		var frame_width: int = int(texture.get_width() / ANIMATION_COLUMNS)
		var frame_height: int = texture.get_height()
		for i in range(ANIMATION_COLUMNS):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
			frames.add_frame(animation_name, atlas)
	animated_sprite.sprite_frames = frames

func _animation_facing_from_move(move: Vector2) -> String:
	if move == Vector2.ZERO:
		return anim_facing
	var n := move.normalized()
	if absf(n.y) < 0.35:
		if n.x > 0.0:
			return "right_up" if _side_vertical_hint < 0 else "right_down"
		return "left_up" if _side_vertical_hint < 0 else "left_down"
	if absf(n.x) < 0.35:
		return "down" if n.y > 0.0 else "up"
	if n.x > 0.0 and n.y > 0.0:
		return "right_down"
	if n.x > 0.0 and n.y < 0.0:
		return "right_up"
	if n.x < 0.0 and n.y > 0.0:
		return "left_down"
	return "left_up"

func _update_animation(move: Vector2) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	var animation_name := "idle_" + anim_facing
	if move != Vector2.ZERO or roll_t > 0.0:
		animation_name = "walk_" + anim_facing
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
	elif not animated_sprite.is_playing():
		animated_sprite.play()
