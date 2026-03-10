extends Node2D
class_name WorldView

var main_ref: Node = null
var _tile_texture_cache: Dictionary = {}

const COLORS := {
	0: Color("7ec850"),
	1: Color("5e5144"),
	2: Color("c8b86a"),
	3: Color("4d8b34"),
	4: Color("8c8f95"),
	5: Color("b67c3d"),
	6: Color("7d6952"),
	10: Color("b9892e"),
	11: Color("d9b66f"),
	12: Color("a7aab3"),
	16: Color("59a8d8"),
	17: Color("1e5d95"),
	18: Color("171327"),
}

const THEME_TINTS := {
	"field": Color(1.0, 1.0, 1.0),
	"lake": Color(0.92, 0.98, 1.02),
	"ruins": Color(0.96, 0.94, 0.90),
}

const TILE_TEXTURE_PATHS := {
	0: "res://assets/tiles/ground/grass_01.png",
	6: "res://assets/tiles/ground/dirt_01.png",
	16: "res://assets/tiles/ground/water_01.png",
	18: "res://assets/tiles/ground/hole_01.png",
	3: "res://assets/tiles/objects/bush_01.png",
	5: "res://assets/tiles/objects/pot_01.png",
	10: "res://assets/tiles/objects/chest_closed.png",
}

func _get_tile_texture(tile_id: int) -> Texture2D:
	if _tile_texture_cache.has(tile_id):
		return _tile_texture_cache[tile_id] as Texture2D
	var path: String = str(TILE_TEXTURE_PATHS.get(tile_id, ""))
	var tex: Texture2D = null
	if path != "" and ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_tile_texture_cache[tile_id] = tex
	return tex

func _draw_tile_visual(px: float, py: float, ts: int, tile_id: int, modulate: Color = Color.WHITE) -> bool:
	var tex: Texture2D = _get_tile_texture(tile_id)
	if tex != null:
		draw_texture_rect(tex, Rect2(px, py, ts, ts), false, modulate)
		return true
	return false

func _draw() -> void:
	if main_ref == null:
		return
	var cm: ChunkManager = main_ref.chunk_manager
	var ts: int = cm.TILE_SIZE
	for coord in main_ref.get_visible_chunk_coords():
		var chunk: Dictionary = cm.get_chunk(coord)
		var origin: Vector2 = cm.chunk_origin(coord)
		var tint: Color = THEME_TINTS.get(str(chunk.get("theme", "field")), Color.WHITE)
		var grid_h: int = int(chunk.get("grid_h", 0))
		var grid_w: int = int(chunk.get("grid_w", 0))
		var ground: Array = chunk.get("ground", []) as Array
		var objects: Array = chunk.get("objects", []) as Array
		for y in range(grid_h):
			var grow: Array = ground[y]
			var orow: Array = objects[y]
			for x in range(grid_w):
				var px: float = origin.x + x * ts
				var py: float = origin.y + y * ts
				var g: int = int(grow[x])
				if not _draw_tile_visual(px, py, ts, g, tint):
					var gc: Color = COLORS.get(g, Color.MAGENTA)
					gc = Color(gc.r * tint.r, gc.g * tint.g, gc.b * tint.b, gc.a)
					draw_rect(Rect2(px, py, ts, ts), gc)
				var obj: int = int(orow[x])
				if obj != cm.OBJECT_NONE:
					if not _draw_tile_visual(px, py, ts, obj):
						_draw_tile_shape(px, py, ts, obj)
		draw_rect(Rect2(origin.x, origin.y, grid_w * ts, grid_h * ts), Color(1,1,1,0), false, 2.0)
	_draw_build_overlay(cm, ts)

func _draw_tile_shape(px: float, py: float, ts: int, tile_id: int) -> void:
	var c: Color = COLORS.get(tile_id, Color.MAGENTA)
	if tile_id == 1:
		draw_rect(Rect2(px, py, ts, ts), c)
		for ry in range(3):
			for rx in range(3):
				var brick := Rect2(px + 4 + rx * 9, py + 5 + ry * 8, 7, 5)
				draw_rect(brick, Color("8b8070"))
	elif tile_id == 3:
		draw_rect(Rect2(px + 6, py + 6, ts - 12, ts - 12), c)
	elif tile_id == 4:
		draw_circle(Vector2(px + ts * 0.5, py + ts * 0.5), ts * 0.28, c)
	elif tile_id == 5:
		draw_rect(Rect2(px + 8, py + 4, ts - 16, ts - 8), c)
	elif tile_id == 10:
		draw_rect(Rect2(px + 4, py + 10, ts - 8, ts - 14), c)
	elif tile_id == 11:
		draw_rect(Rect2(px + 4, py + 10, ts - 8, ts - 14), Color("8f6f2d"))
		draw_rect(Rect2(px + 4, py + 16, ts - 8, ts - 20), Color("704b1f"))
	elif tile_id == 12:
		draw_rect(Rect2(px + 4, py + 4, ts - 8, ts - 8), c)
		draw_rect(Rect2(px + 7, py + 7, ts - 14, ts - 14), Color("8d9098"), false, 2.0)
	else:
		draw_rect(Rect2(px + 4, py + 4, ts - 8, ts - 8), c)

func _draw_build_overlay(cm: ChunkManager, ts: int) -> void:
	if not bool(main_ref.build_mode):
		return
	var view_size: Vector2 = main_ref.get_viewport_rect().size
	var cam_pos: Vector2 = main_ref.camera.position
	var draw_rect_area: Rect2 = Rect2(cam_pos - view_size * 0.5, view_size)
	if bool(main_ref.grid_near_cursor_only):
		draw_rect_area = Rect2(main_ref.build_cursor_world - Vector2(6.5 * ts, 6.5 * ts), Vector2(13.0 * ts, 13.0 * ts))
	var left: int = floori(draw_rect_area.position.x / float(ts))
	var top: int = floori(draw_rect_area.position.y / float(ts))
	var right: int = floori((draw_rect_area.position.x + draw_rect_area.size.x) / float(ts))
	var bottom: int = floori((draw_rect_area.position.y + draw_rect_area.size.y) / float(ts))
	for gx in range(left, right + 2):
		var px: float = gx * ts
		draw_line(Vector2(px, top * ts), Vector2(px, (bottom + 1) * ts), Color(1,1,1,0.08), 1.0)
	for gy in range(top, bottom + 2):
		var py: float = gy * ts
		draw_line(Vector2(left * ts, py), Vector2((right + 1) * ts, py), Color(1,1,1,0.08), 1.0)
	var brush: int = int(main_ref.build_brush_size)
	var half_brush: int = int((brush - 1) / 2)
	var start: Vector2 = main_ref.build_cursor_world - Vector2(half_brush * ts + ts / 2.0, half_brush * ts + ts / 2.0)
	var size_px: int = brush * ts
	draw_rect(Rect2(start, Vector2(size_px, size_px)), Color(1.0, 0.95, 0.3, 0.18), true)
	draw_rect(Rect2(start, Vector2(size_px, size_px)), Color(1.0, 0.95, 0.3, 0.95), false, 2.0)
	draw_circle(main_ref.player_world_pos, 10.0, Color(0.3, 0.9, 1.0, 0.18))
