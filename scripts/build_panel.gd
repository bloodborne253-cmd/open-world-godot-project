extends Panel
class_name BuildPanelUI

var main_ref: Node = null
var _tile_texture_cache: Dictionary = {}

const TILE_COLORS := {
	0: Color("7ec850"),
	1: Color("7a634d"),
	2: Color("c8b86a"),
	3: Color("4d8b34"),
	4: Color("8c8f95"),
	5: Color("b67c3d"),
	6: Color("7d6952"),
	10: Color("b9892e"),
	16: Color("59a8d8"),
	17: Color("1e5d95"),
	18: Color("171327"),
}

const TILE_DESCRIPTIONS := {
	0: "Grass floor for open ground.",
	1: "Stone brick wall.",
	2: "Sand for beaches and paths.",
	3: "Bush object. Cuttable.",
	4: "Rock obstacle.",
	5: "Pot prop. Breakable.",
	6: "Packed dirt floor.",
	10: "Chest object. Interactable.",
	16: "Shallow water. Slows movement.",
	17: "Deep water. Blocks movement.",
	18: "Hole or pit hazard.",
}

const TILE_TEXTURE_PATHS := {
	0: "res://assets/tiles/ground/grass_01.png",
	6: "res://assets/tiles/ground/dirt_01.png",
	16: "res://assets/tiles/ground/water_01.png",
	18: "res://assets/tiles/ground/hole_01.png",
	3: "res://assets/tiles/objects/bush_01.png",
	5: "res://assets/tiles/objects/pot_big_9.png",
}

const CHEST_SHEET_PATH := "res://assets/tiles/objects/chest.png"
const CHEST_CELL_SIZE := Vector2i(36, 25)

func _get_pot_sheet_texture(tile_id: int) -> Texture2D:
	return null

func _get_chest_sheet_texture(tile_id: int) -> Texture2D:
	if tile_id != 10 and tile_id != 11:
		return null
	var sheet: Texture2D = load(CHEST_SHEET_PATH) as Texture2D
	if sheet == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(0, 0), Vector2(CHEST_CELL_SIZE))
	return atlas

func _get_tile_texture(tile_id: int) -> Texture2D:
	if _tile_texture_cache.has(tile_id):
		return _tile_texture_cache[tile_id] as Texture2D
	var path: String = str(TILE_TEXTURE_PATHS.get(tile_id, ""))
	var tex: Texture2D = _get_pot_sheet_texture(tile_id)
	if tex == null:
		tex = _get_chest_sheet_texture(tile_id)
	if tex == null and path != "" and ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_tile_texture_cache[tile_id] = tex
	return tex

func _draw() -> void:
	if main_ref == null:
		return
	var font: Font = get_theme_default_font()
	if font == null:
		return

	if not bool(main_ref.palette_open):
		_draw_hotbar(font)
		return

	_draw_box(Rect2(Vector2.ZERO, size), Color(0.07, 0.09, 0.10, 0.94), Color(0.84, 0.75, 0.49), 3)

	var top_tabs: Array[String] = ["Floor", "Walls", "Objects", "Special"]
	var page_name: String = str(main_ref._get_current_page_name())
	var subtab_name: String = str(main_ref._get_current_subtab_name())
	var subtabs: Array = main_ref._get_current_subtabs()
	var items: Array = main_ref._get_current_page_items()
	var current_id: int = int(main_ref.get_current_build_tile())
	var current_name: String = str(main_ref.get_current_build_tile_name())
	var sel_i: int = clampi(int(main_ref.build_item_index), 0, maxi(0, items.size() - 1))

	var outer_pad: float = 20.0
	var top_y: float = 20.0
	var tab_h: float = 34.0
	var tab_gap: float = 10.0
	var tab_w: float = 132.0
	var tabs_total: float = top_tabs.size() * tab_w + (top_tabs.size() - 1) * tab_gap
	var tabs_x: float = floor((size.x - tabs_total) * 0.5)
	for i in range(top_tabs.size()):
		var r: Rect2 = Rect2(tabs_x + i * (tab_w + tab_gap), top_y, tab_w, tab_h)
		var active: bool = top_tabs[i] == page_name
		_draw_box(r, Color(0.82, 0.75, 0.50, 0.96) if active else Color(0.15, 0.15, 0.16, 0.96), Color(0.84, 0.75, 0.49), 2)
		draw_string(font, r.position + Vector2(18, 24), top_tabs[i], HORIZONTAL_ALIGNMENT_LEFT, tab_w - 20.0, 18, Color(0.97, 0.95, 0.90))

	var sub_y: float = top_y + tab_h + 14.0
	var sub_h: float = 30.0
	var sub_bar: Rect2 = Rect2(outer_pad + 10.0, sub_y, size.x - 2.0 * (outer_pad + 10.0), sub_h)
	_draw_box(sub_bar, Color(0.13, 0.14, 0.16, 0.96), Color(0.44, 0.39, 0.30), 1)
	var sub_gap: float = 8.0
	var sub_count: int = maxi(1, subtabs.size())
	var sub_w: float = minf(160.0, (sub_bar.size.x - 20.0 - (sub_count - 1) * sub_gap) / float(sub_count))
	var sub_total: float = sub_count * sub_w + (sub_count - 1) * sub_gap
	var sub_x: float = sub_bar.position.x + floor((sub_bar.size.x - sub_total) * 0.5)
	for i in range(subtabs.size()):
		var sr: Rect2 = Rect2(sub_x + i * (sub_w + sub_gap), sub_y + 3.0, sub_w, sub_h - 6.0)
		var active_sub: bool = str((subtabs[i] as Dictionary).get("name", "")) == subtab_name
		_draw_box(sr, Color(0.23, 0.22, 0.20, 0.96) if active_sub else Color(0.15, 0.15, 0.16, 0.96), Color(0.50, 0.45, 0.34), 1)
		draw_string(font, sr.position + Vector2(16, 18), str((subtabs[i] as Dictionary).get("name", "Items")), HORIZONTAL_ALIGNMENT_LEFT, sub_w - 18.0, 16, Color(0.96, 0.94, 0.88))

	var footer_h: float = 34.0
	var content_y: float = sub_bar.end.y + 14.0
	var content_h: float = size.y - content_y - footer_h - 16.0
	var preview_w: float = 228.0
	var gap: float = 16.0
	var grid_rect: Rect2 = Rect2(outer_pad, content_y, size.x - outer_pad * 2.0 - preview_w - gap, content_h)
	var preview_rect: Rect2 = Rect2(grid_rect.end.x + gap, content_y, preview_w, content_h)
	var footer_rect: Rect2 = Rect2(outer_pad, size.y - footer_h - 10.0, size.x - outer_pad * 2.0, footer_h)
	_draw_box(grid_rect, Color(0.08, 0.10, 0.12, 0.24), Color(0.44, 0.39, 0.30), 1)
	_draw_box(preview_rect, Color(0.09, 0.10, 0.12, 0.96), Color(0.84, 0.75, 0.49), 2)
	_draw_box(footer_rect, Color(0.09, 0.10, 0.12, 0.96), Color(0.44, 0.39, 0.30), 1)

	var cols: int = 4
	var rows: int = 2
	var pad: float = 12.0
	var cell_gap: float = 10.0
	var cell_w: float = floor((grid_rect.size.x - pad * 2.0 - cell_gap * (cols - 1)) / cols)
	var cell_h: float = floor((grid_rect.size.y - pad * 2.0 - cell_gap * (rows - 1)) / rows)
	var grid_cap: int = cols * rows
	for i in range(mini(items.size(), grid_cap)):
		var col: int = i % cols
		var row: int = int(i / cols)
		var cell: Rect2 = Rect2(grid_rect.position.x + pad + col * (cell_w + cell_gap), grid_rect.position.y + pad + row * (cell_h + cell_gap), cell_w, cell_h)
		var tile_id: int = int(items[i])
		var active_item: bool = i == sel_i
		_draw_box(cell, Color(0.14, 0.14, 0.16, 0.95), Color(0.92, 0.83, 0.41) if active_item else Color(0.38, 0.34, 0.27), 2)
		var icon_size: float = minf(minf(cell_w, cell_h) - 24.0, 56.0)
		var icon_rect: Rect2 = Rect2(cell.position.x + floor((cell_w - icon_size) * 0.5), cell.position.y + floor((cell_h - icon_size) * 0.5), icon_size, icon_size)
		_draw_tile_icon(icon_rect, tile_id)

	var title_y: float = preview_rect.position.y + 34.0
	draw_string(font, Vector2(preview_rect.position.x + 18.0, title_y), current_name, HORIZONTAL_ALIGNMENT_LEFT, preview_rect.size.x - 36.0, 24, Color(0.97, 0.95, 0.90))
	var picon: Rect2 = Rect2(preview_rect.position.x + floor((preview_rect.size.x - 84.0) * 0.5), preview_rect.position.y + 58.0, 84.0, 84.0)
	_draw_tile_icon(picon, current_id)
	draw_string(font, Vector2(preview_rect.position.x + 18.0, preview_rect.position.y + 176.0), "ID: %d" % current_id, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.74, 0.92, 0.42))
	draw_line(Vector2(preview_rect.position.x + 18.0, preview_rect.position.y + 192.0), Vector2(preview_rect.end.x - 18.0, preview_rect.position.y + 192.0), Color(0.43, 0.38, 0.31), 1.0)
	var desc: String = str(TILE_DESCRIPTIONS.get(current_id, "Placeable build tile."))
	_draw_wrapped_text(font, desc, Rect2(preview_rect.position.x + 18.0, preview_rect.position.y + 208.0, preview_rect.size.x - 36.0, preview_rect.size.y - 226.0), 15, Color(0.95, 0.93, 0.87), 18.0)

	var footer: String = "Stick Move  D-Pad Nudge  L1/R1 Group  L2/R2 Tab  A Place  B Erase  Y Back"
	draw_string(font, Vector2(footer_rect.position.x + 14.0, footer_rect.position.y + 22.0), footer, HORIZONTAL_ALIGNMENT_LEFT, footer_rect.size.x - 28.0, 14, Color(0.94, 0.92, 0.87))

func _draw_hotbar(font: Font) -> void:
	var items: Array = main_ref.get_current_hotbar_items()
	if items.is_empty():
		return
	var current_id: int = int(main_ref.get_current_build_tile())
	var current_name: String = str(main_ref.get_current_build_tile_name())
	var group_name: String = str(main_ref.get_current_hotbar_group_name())
	var bar_rect: Rect2 = Rect2(Vector2.ZERO, size)

	var pad: float = 8.0
	var panel_h: float = size.y - pad * 2.0
	var left_w: float = 132.0
	var right_w: float = 190.0
	var center_gap: float = 10.0
	var left_rect: Rect2 = Rect2(pad, pad, left_w, panel_h)
	var right_rect: Rect2 = Rect2(size.x - right_w - pad, pad, right_w, panel_h)
	var icons_rect: Rect2 = Rect2(left_rect.end.x + center_gap, pad, right_rect.position.x - (left_rect.end.x + center_gap) - center_gap, panel_h)

	_draw_box(left_rect, Color(0.07, 0.09, 0.10, 0.90), Color(0.84, 0.75, 0.49), 1)
	_draw_box(right_rect, Color(0.07, 0.09, 0.10, 0.90), Color(0.84, 0.75, 0.49), 1)

	draw_string(font, left_rect.position + Vector2(12.0, 20.0), group_name, HORIZONTAL_ALIGNMENT_LEFT, left_rect.size.x - 20.0, 15, Color(0.97, 0.95, 0.90))
	draw_string(font, left_rect.position + Vector2(12.0, 40.0), current_name, HORIZONTAL_ALIGNMENT_LEFT, left_rect.size.x - 20.0, 14, Color(0.74, 0.92, 0.42))

	var count: int = items.size()
	var gap: float = 8.0
	var icon_size: float = minf(36.0, floor((icons_rect.size.x - gap * maxf(0.0, float(count - 1))) / maxf(1.0, float(count))))
	var total_w: float = count * icon_size + maxf(0.0, float(count - 1)) * gap
	var start_x: float = icons_rect.position.x + floor((icons_rect.size.x - total_w) * 0.5)
	for i in range(count):
		var tile_id: int = int(items[i])
		var r: Rect2 = Rect2(start_x + i * (icon_size + gap), icons_rect.position.y + floor((icons_rect.size.y - icon_size) * 0.5), icon_size, icon_size)
		_draw_box(r, Color(0.14, 0.14, 0.16, 0.92), Color(0.92, 0.83, 0.41) if tile_id == current_id else Color(0.38, 0.34, 0.27), 2)
		_draw_tile_icon(r.grow(-6.0), tile_id)

	draw_string(font, right_rect.position + Vector2(10.0, 18.0), "L2/R2 Group", HORIZONTAL_ALIGNMENT_LEFT, right_rect.size.x - 20.0, 13, Color(0.94, 0.92, 0.87))
	draw_string(font, right_rect.position + Vector2(10.0, 34.0), "L1/R1 Tile", HORIZONTAL_ALIGNMENT_LEFT, right_rect.size.x - 20.0, 13, Color(0.94, 0.92, 0.87))
	draw_string(font, right_rect.position + Vector2(10.0, 50.0), "A Place   B Erase", HORIZONTAL_ALIGNMENT_LEFT, right_rect.size.x - 20.0, 13, Color(0.94, 0.92, 0.87))
	draw_string(font, right_rect.position + Vector2(10.0, 66.0), "Y Palette   X Brush", HORIZONTAL_ALIGNMENT_LEFT, right_rect.size.x - 20.0, 13, Color(0.94, 0.92, 0.87))

func _draw_wrapped_text(font: Font, text: String, rect: Rect2, font_size: int, color: Color, line_height: float) -> void:
	var words: PackedStringArray = text.split(" ", false)
	var line: String = ""
	var y: float = rect.position.y
	for word in words:
		var candidate: String = word if line == "" else line + " " + word
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= rect.size.x:
			line = candidate
		else:
			if line != "":
				draw_string(font, Vector2(rect.position.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x, font_size, color)
				y += line_height
			line = word
			if y > rect.end.y:
				return
	if line != "" and y <= rect.end.y:
		draw_string(font, Vector2(rect.position.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x, font_size, color)

func _draw_box(r: Rect2, fill: Color, border: Color, bw: int) -> void:
	draw_rect(r, fill, true)
	if bw > 0:
		draw_rect(r, border, false, float(bw))

func _draw_tile_icon(r: Rect2, tile_id: int) -> void:
	var tex: Texture2D = _get_tile_texture(tile_id)
	if tex != null:
		draw_texture_rect(tex, r, false)
		draw_rect(r, Color(0, 0, 0, 0.35), false, 2.0)
		return
	var base: Color = Color(TILE_COLORS.get(tile_id, Color.MAGENTA))
	draw_rect(r, base, true)
	draw_rect(r, Color(0, 0, 0, 0.35), false, 2.0)
	if tile_id == 3:
		draw_rect(Rect2(r.position.x + 8, r.position.y + 8, r.size.x - 16, r.size.y - 16), Color("79b74f"), true)
	elif tile_id == 4:
		draw_circle(r.position + r.size * 0.5, r.size.x * 0.26, Color("6f737b"))
		draw_circle(r.position + Vector2(r.size.x * 0.36, r.size.y * 0.46), r.size.x * 0.14, Color("969aa2"))
		draw_circle(r.position + Vector2(r.size.x * 0.62, r.size.y * 0.56), r.size.x * 0.16, Color("8a8f98"))
	elif tile_id == 5:
		draw_rect(Rect2(r.position.x + 10, r.position.y + 8, r.size.x - 20, r.size.y - 16), Color("e4b16f"), true)
		draw_rect(Rect2(r.position.x + 16, r.position.y + 5, r.size.x - 32, 8), Color("c88c46"), true)
	elif tile_id == 10:
		draw_rect(Rect2(r.position.x + 6, r.position.y + 16, r.size.x - 12, r.size.y - 22), Color("704b1f"), true)
		draw_rect(Rect2(r.position.x + 8, r.position.y + 8, r.size.x - 16, 14), Color("b9892e"), true)
	elif tile_id == 16:
		for i in range(3):
			draw_line(Vector2(r.position.x + 6, r.position.y + 10 + i * 12), Vector2(r.end.x - 6, r.position.y + 8 + i * 12), Color(0.62, 0.90, 0.95, 0.7), 2.0)
	elif tile_id == 17:
		draw_rect(Rect2(r.position.x + 5, r.position.y + 5, r.size.x - 10, r.size.y - 10), Color("0e3b63"), true)
		for i in range(3):
			draw_line(Vector2(r.position.x + 8, r.position.y + 12 + i * 14), Vector2(r.end.x - 8, r.position.y + 10 + i * 14), Color(0.18, 0.44, 0.61, 0.7), 2.0)
	elif tile_id == 1:
		var bw: float = maxf(7.0, floor(r.size.x / 4.0))
		var bh: float = maxf(6.0, floor(r.size.y / 5.0))
		for y in range(3):
			for x in range(3):
				var brick: Rect2 = Rect2(r.position.x + 6 + x * (bw + 3.0), r.position.y + 6 + y * (bh + 4.0), bw, bh)
				draw_rect(brick, Color("8b8070"), true)
				draw_rect(brick, Color("5b5146"), false, 1.0)
	elif tile_id == 2:
		for i in range(3):
			draw_line(Vector2(r.position.x + 8, r.position.y + 12 + i * 10), Vector2(r.end.x - 8, r.position.y + 10 + i * 10), Color(0.88, 0.82, 0.58, 0.65), 2.0)
	elif tile_id == 6:
		for i in range(3):
			draw_line(Vector2(r.position.x + 8, r.position.y + 12 + i * 12), Vector2(r.end.x - 8, r.position.y + 10 + i * 12), Color(0.62, 0.51, 0.39, 0.75), 2.0)
