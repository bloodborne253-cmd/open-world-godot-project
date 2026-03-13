extends Node2D
class_name WorldPickup

const PICKUP_RADIUS := 18.0
const PICKUP_DELAY := 0.22

@export var pickup_kind: String = "coin"
@export var value: int = 1

var drift: Vector2 = Vector2.ZERO
var bob_t: float = 0.0
var life_t: float = 12.0
var pickup_delay_t: float = PICKUP_DELAY
var main_ref: Node = null

func _ready() -> void:
	z_index = 30
	set_process(true)

func setup(kind: String, amount: int, start_drift: Vector2 = Vector2.ZERO) -> void:
	pickup_kind = kind
	value = amount
	drift = start_drift
	pickup_delay_t = PICKUP_DELAY
	queue_redraw()

func _process(delta: float) -> void:
	bob_t += delta
	life_t -= delta
	pickup_delay_t = max(pickup_delay_t - delta, 0.0)
	position += drift * delta
	drift = drift.move_toward(Vector2.ZERO, 220.0 * delta)
	if life_t <= 0.0:
		queue_free()
		return
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		queue_redraw()
		return
	if pickup_delay_t <= 0.0:
		var to_player: Vector2 = player.global_position - global_position
		if to_player.length() <= PICKUP_RADIUS:
			_collect(player)
			return
	queue_redraw()

func _collect(player: Node) -> void:
	if pickup_kind == "heart":
		if player.has_method("heal"):
			player.heal(value)
			if main_ref != null and main_ref.has_method("show_status"):
				main_ref.show_status("+%d health" % value)
	else:
		if player.has_method("add_coins"):
			player.add_coins(value)
			if main_ref != null and main_ref.has_method("show_status"):
				main_ref.show_status("+%d coin%s" % [value, "" if value == 1 else "s"])
	queue_free()

func _draw() -> void:
	var bob: float = sin(bob_t * 4.0) * 2.0
	if pickup_kind == "heart":
		var pts := PackedVector2Array([
			Vector2(0, 9 + bob),
			Vector2(-10, -1 + bob),
			Vector2(-6, -8 + bob),
			Vector2(0, -4 + bob),
			Vector2(6, -8 + bob),
			Vector2(10, -1 + bob),
		])
		draw_colored_polygon(pts, Color(0.94, 0.28, 0.38, 0.95))
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(1, 1, 1, 0.9), 1.5)
		draw_circle(Vector2(0, 11 + bob), 9.5, Color(0, 0, 0, 0.16))
	else:
		draw_circle(Vector2(0, 8 + bob), 9.5, Color(0, 0, 0, 0.16))
		draw_circle(Vector2(0, bob), 8.0, Color(0.98, 0.86, 0.23, 0.95))
		draw_arc(Vector2(0, bob), 8.0, 0.0, TAU, 24, Color(1.0, 0.97, 0.65, 0.95), 2.0)
		draw_line(Vector2(-2, -5 + bob), Vector2(2, 5 + bob), Color(1, 0.98, 0.75, 0.9), 1.5)
