extends RefCounted
class_name ChunkManager

const TILE_SIZE := 32
const CHUNK_W := 48
const CHUNK_H := 27
const OBJECT_NONE := -1

const TILE_GRASS := 0
const TILE_WALL := 1
const TILE_SAND := 2
const TILE_BUSH := 3
const TILE_ROCK := 4
const TILE_POT := 5
const TILE_DIRT := 6
const TILE_CHEST_CLOSED := 10
const TILE_CHEST_OPEN := 11
const TILE_PUSH_BLOCK := 12
const TILE_WATER := 16
const TILE_DEEP := 17
const TILE_HOLE := 18

var chunks: Dictionary = {}

func chunk_pixel_size() -> Vector2:
	return Vector2(CHUNK_W * TILE_SIZE, CHUNK_H * TILE_SIZE)

func chunk_key(coord: Vector2i) -> String:
	return "%d,%d" % [coord.x, coord.y]

func world_to_chunk_coord(world_pos: Vector2) -> Vector2i:
	var size: Vector2 = chunk_pixel_size()
	return Vector2i(floori(world_pos.x / size.x), floori(world_pos.y / size.y))

func world_to_local_tile(world_pos: Vector2) -> Vector2i:
	var tx := floori(world_pos.x / float(TILE_SIZE))
	var ty := floori(world_pos.y / float(TILE_SIZE))
	return Vector2i(posmod(tx, CHUNK_W), posmod(ty, CHUNK_H))

func chunk_origin(coord: Vector2i) -> Vector2:
	var size: Vector2 = chunk_pixel_size()
	return Vector2(coord.x * size.x, coord.y * size.y)

func get_loaded_chunks() -> Dictionary:
	return chunks

func ensure_chunks_around(world_pos: Vector2, radius: int = 1) -> void:
	var center := world_to_chunk_coord(world_pos)
	for cy in range(center.y - radius, center.y + radius + 1):
		for cx in range(center.x - radius, center.x + radius + 1):
			ensure_chunk(Vector2i(cx, cy))

func trim_chunks_around(world_pos: Vector2, keep_radius: int = 2) -> bool:
	var center := world_to_chunk_coord(world_pos)
	var to_remove: Array = []
	for key in chunks.keys():
		var parts: PackedStringArray = str(key).split(",")
		if parts.size() != 2:
			continue
		var cx := int(parts[0])
		var cy := int(parts[1])
		if abs(cx - center.x) > keep_radius or abs(cy - center.y) > keep_radius:
			to_remove.append(key)
	for key in to_remove:
		chunks.erase(key)
	return to_remove.size() > 0

func get_visible_chunk_coords(view_rect: Rect2, margin_chunks: int = 1) -> Array[Vector2i]:
	var chunk_size: Vector2 = chunk_pixel_size()
	var left := floori(view_rect.position.x / chunk_size.x) - margin_chunks
	var top := floori(view_rect.position.y / chunk_size.y) - margin_chunks
	var right := floori((view_rect.position.x + view_rect.size.x) / chunk_size.x) + margin_chunks
	var bottom := floori((view_rect.position.y + view_rect.size.y) / chunk_size.y) + margin_chunks
	var coords: Array[Vector2i] = []
	for cy in range(top, bottom + 1):
		for cx in range(left, right + 1):
			coords.append(Vector2i(cx, cy))
	return coords

func regenerate_chunks_around(world_pos: Vector2, radius: int = 2) -> void:
	var center := world_to_chunk_coord(world_pos)
	for cy in range(center.y - radius, center.y + radius + 1):
		for cx in range(center.x - radius, center.x + radius + 1):
			var coord := Vector2i(cx, cy)
			chunks.erase(chunk_key(coord))
			ensure_chunk(coord)

func ensure_chunk(coord: Vector2i) -> Dictionary:
	var key: String = chunk_key(coord)
	if chunks.has(key):
		return chunks[key]
	var chunk: Dictionary = _generate_chunk(coord)
	chunks[key] = chunk
	return chunk

func get_chunk(coord: Vector2i) -> Dictionary:
	return ensure_chunk(coord)

func _noiseish(seed: int, x: int, y: int) -> int:
	var n := seed + x * 374761393 + y * 668265263
	n = (n ^ (n >> 13)) * 1274126177
	return abs(n ^ (n >> 16))

func _make_row(fill_value: int) -> Array:
	var row: Array = []
	row.resize(CHUNK_W)
	for i in range(CHUNK_W):
		row[i] = fill_value
	return row

func _generate_chunk(coord: Vector2i) -> Dictionary:
	var seed: int = coord.x * 92821 + coord.y * 68917 + 1337
	var theme: String = "field"
	var modv: int = posmod(coord.x + coord.y, 6)
	if modv == 2:
		theme = "lake"
	elif modv == 4:
		theme = "ruins"

	var ground: Array = []
	var objects: Array = []
	ground.resize(CHUNK_H)
	objects.resize(CHUNK_H)
	for y in range(CHUNK_H):
		ground[y] = _make_row(TILE_GRASS)
		objects[y] = _make_row(OBJECT_NONE)

	for x in range(CHUNK_W):
		if _noiseish(seed, x, 100) % 11 < 2:
			(ground[int(CHUNK_H / 2)] as Array)[x] = TILE_DIRT
	for y in range(CHUNK_H):
		if _noiseish(seed, 200, y) % 12 < 2:
			(ground[y] as Array)[int(CHUNK_W / 2)] = TILE_DIRT

	for y in range(CHUNK_H):
		var grow: Array = ground[y]
		var orow: Array = objects[y]
		for x in range(CHUNK_W):
			var roll: int = _noiseish(seed, x, y) % 1000
			if theme == "lake":
				if roll < 55:
					grow[x] = TILE_WATER
				elif roll < 64:
					grow[x] = TILE_DEEP
				elif roll < 84:
					grow[x] = TILE_SAND
				elif roll < 105:
					orow[x] = TILE_BUSH
				elif roll < 114:
					orow[x] = TILE_ROCK
			elif theme == "ruins":
				if roll < 30:
					orow[x] = TILE_ROCK
				elif roll < 48:
					orow[x] = TILE_BUSH
				elif roll < 64:
					grow[x] = TILE_DIRT
				elif roll < 68:
					orow[x] = TILE_POT
			else:
				if roll < 38:
					orow[x] = TILE_BUSH
				elif roll < 48:
					orow[x] = TILE_ROCK
				elif roll < 54:
					orow[x] = TILE_POT

	if coord == Vector2i.ZERO:
		for y in range(8, 18):
			var row: Array = ground[y]
			for x in range(10, 38):
				row[x] = TILE_GRASS
			var orow0: Array = objects[y]
			for x in range(10, 38):
				orow0[x] = OBJECT_NONE
		for x in range(12, 36):
			(ground[13] as Array)[x] = TILE_DIRT
		(objects[13] as Array)[22] = TILE_CHEST_CLOSED
		(objects[13] as Array)[25] = TILE_PUSH_BLOCK

	if coord != Vector2i.ZERO and _noiseish(seed, 9, 9) % 9 == 0:
		var cx := 8 + _noiseish(seed, 11, 3) % (CHUNK_W - 16)
		var cy := 6 + _noiseish(seed, 7, 5) % (CHUNK_H - 12)
		(objects[cy] as Array)[cx] = TILE_CHEST_CLOSED

	return {
		"coord": coord,
		"theme": theme,
		"ground": ground,
		"objects": objects,
		"grid_w": CHUNK_W,
		"grid_h": CHUNK_H,
	}

func get_ground_at_world(world_pos: Vector2) -> int:
	var chunk: Dictionary = ensure_chunk(world_to_chunk_coord(world_pos))
	var local: Vector2i = world_to_local_tile(world_pos)
	return int((chunk["ground"][local.y] as Array)[local.x])

func get_object_at_world(world_pos: Vector2) -> int:
	var chunk: Dictionary = ensure_chunk(world_to_chunk_coord(world_pos))
	var local: Vector2i = world_to_local_tile(world_pos)
	return int((chunk["objects"][local.y] as Array)[local.x])

func get_tile_at_world(world_pos: Vector2) -> int:
	var obj: int = get_object_at_world(world_pos)
	if obj != OBJECT_NONE:
		return obj
	return get_ground_at_world(world_pos)

func set_ground_at_world(world_pos: Vector2, tile_id: int) -> void:
	var chunk: Dictionary = ensure_chunk(world_to_chunk_coord(world_pos))
	var local: Vector2i = world_to_local_tile(world_pos)
	(chunk["ground"][local.y] as Array)[local.x] = tile_id

func set_object_at_world(world_pos: Vector2, tile_id: int) -> void:
	var chunk: Dictionary = ensure_chunk(world_to_chunk_coord(world_pos))
	var local: Vector2i = world_to_local_tile(world_pos)
	(chunk["objects"][local.y] as Array)[local.x] = tile_id

func clear_object_at_world(world_pos: Vector2) -> void:
	set_object_at_world(world_pos, OBJECT_NONE)

func set_tile_at_world(world_pos: Vector2, tile_id: int) -> void:
	if is_ground_tile(tile_id):
		set_ground_at_world(world_pos, tile_id)
	else:
		set_object_at_world(world_pos, tile_id)

func is_ground_tile(tile_id: int) -> bool:
	return tile_id in [TILE_GRASS, TILE_SAND, TILE_DIRT, TILE_WATER, TILE_DEEP, TILE_HOLE]

func is_object_tile(tile_id: int) -> bool:
	return tile_id in [TILE_WALL, TILE_BUSH, TILE_ROCK, TILE_POT, TILE_CHEST_CLOSED, TILE_CHEST_OPEN, TILE_PUSH_BLOCK]

func is_solid_tile(tile_id: int) -> bool:
	return tile_id in [TILE_WALL, TILE_BUSH, TILE_ROCK, TILE_POT, TILE_CHEST_CLOSED, TILE_CHEST_OPEN, TILE_PUSH_BLOCK, TILE_DEEP]

func is_slow_tile(tile_id: int) -> bool:
	return tile_id == TILE_WATER

func can_cut_tile(tile_id: int) -> bool:
	return tile_id == TILE_BUSH or tile_id == TILE_POT

func replacement_for_cut(tile_id: int) -> int:
	return TILE_DIRT if tile_id == TILE_POT else TILE_GRASS

func erase_default_for_page(page_name: String) -> int:
	return TILE_GRASS if page_name in ["Ground", "Floor", "Special"] else OBJECT_NONE

func is_body_colliding(world_pos: Vector2, body_size: Vector2) -> bool:
	var half: Vector2 = body_size * 0.5
	var rect: Rect2 = Rect2(world_pos - half, body_size)
	var left: int = floori(rect.position.x / float(TILE_SIZE))
	var right: int = floori((rect.position.x + rect.size.x - 0.001) / float(TILE_SIZE))
	var top: int = floori(rect.position.y / float(TILE_SIZE))
	var bottom: int = floori((rect.position.y + rect.size.y - 0.001) / float(TILE_SIZE))
	for ty in range(top, bottom + 1):
		for tx in range(left, right + 1):
			var wp: Vector2 = Vector2((tx + 0.5) * TILE_SIZE, (ty + 0.5) * TILE_SIZE)
			if is_solid_tile(get_tile_at_world(wp)):
				return true
	return false

func sword_hit_world(rect: Rect2) -> bool:
	var changed: bool = false
	var start_tx: int = floori(rect.position.x / float(TILE_SIZE))
	var end_tx: int = floori((rect.position.x + rect.size.x) / float(TILE_SIZE))
	var start_ty: int = floori(rect.position.y / float(TILE_SIZE))
	var end_ty: int = floori((rect.position.y + rect.size.y) / float(TILE_SIZE))
	for ty in range(start_ty, end_ty + 1):
		for tx in range(start_tx, end_tx + 1):
			var wp: Vector2 = Vector2((tx + 0.5) * TILE_SIZE, (ty + 0.5) * TILE_SIZE)
			var tile_id := get_object_at_world(wp)
			if can_cut_tile(tile_id):
				clear_object_at_world(wp)
				changed = true
	return changed

func try_open_chest(player_world_pos: Vector2) -> bool:
	var facing_offsets: Array[Vector2] = [Vector2.ZERO, Vector2(0, -24), Vector2(24, 0), Vector2(0, 24), Vector2(-24, 0)]
	for off: Vector2 in facing_offsets:
		var wp: Vector2 = player_world_pos + off
		if get_object_at_world(wp) == TILE_CHEST_CLOSED:
			set_object_at_world(wp, TILE_CHEST_OPEN)
			return true
	return false


func is_hole_tile(tile_id: int) -> bool:
	return tile_id == TILE_HOLE

func can_place_object_at_world(world_pos: Vector2) -> bool:
	return not is_hole_tile(get_ground_at_world(world_pos))

func can_push_block_into_world(world_pos: Vector2) -> bool:
	if get_object_at_world(world_pos) != OBJECT_NONE:
		return false
	var ground_id: int = get_ground_at_world(world_pos)
	if ground_id in [TILE_WATER, TILE_DEEP, TILE_HOLE]:
		return false
	return true

func try_push_block_at_world(world_pos: Vector2, push_dir: Vector2) -> bool:
	if push_dir == Vector2.ZERO:
		return false
	if get_object_at_world(world_pos) != TILE_PUSH_BLOCK:
		return false
	var target: Vector2 = world_pos + push_dir * TILE_SIZE
	if not can_push_block_into_world(target):
		return false
	clear_object_at_world(world_pos)
	set_object_at_world(target, TILE_PUSH_BLOCK)
	return true
