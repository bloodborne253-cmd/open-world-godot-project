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

var facing := "down"
var attack_t := 0.0
var attack_applied := false
var roll_t := 0.0
var roll_cd := 0.0
var roll_dir := Vector2.ZERO
var last_move := Vector2.DOWN

func _process(delta: float) -> void:
	queue_redraw()
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
	if absf(move.x) > absf(move.y):
		facing = "right" if move.x > 0 else "left"
	else:
		facing = "down" if move.y > 0 else "up"

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

func movement_velocity() -> Vector2:
	if roll_t > 0.0:
		return roll_dir * ROLL_SPEED
	var move := get_input_vector()
	update_facing(move)
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

func _draw() -> void:
	draw_rect(Rect2(Vector2(-12, -12), Vector2(24, 24)), Color(0.75, 0.88, 0.55))
	draw_rect(Rect2(Vector2(-7, -16), Vector2(14, 8)), Color(0.95, 0.85, 0.63))
	match facing:
		"up":
			draw_rect(Rect2(Vector2(-3, -18), Vector2(6, 4)), Color(0.2, 0.35, 0.9))
		"down":
			draw_rect(Rect2(Vector2(-3, 14), Vector2(6, 4)), Color(0.2, 0.35, 0.9))
		"left":
			draw_rect(Rect2(Vector2(-18, -3), Vector2(4, 6)), Color(0.2, 0.35, 0.9))
		"right":
			draw_rect(Rect2(Vector2(14, -3), Vector2(4, 6)), Color(0.2, 0.35, 0.9))
	if attack_t > 0.0:
		var sword := sword_rect()
		draw_rect(Rect2(to_local(sword.position), sword.size), Color(0.9, 0.9, 1.0, 0.75))
