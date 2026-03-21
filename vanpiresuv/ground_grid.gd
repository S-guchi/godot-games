extends Node2D

## Infinite scrolling grid background to show player movement

const GRID_SIZE := 64
const GRID_COLOR := Color(0.15, 0.18, 0.25)
const BG_COLOR := Color(0.08, 0.09, 0.12)
const DOT_COLOR := Color(0.22, 0.25, 0.35)
const CROSS_COLOR := Color(0.12, 0.14, 0.2)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var cam := get_viewport().get_camera_2d()
	if not cam:
		return

	var zoom := cam.zoom
	var vp_size := get_viewport_rect().size / zoom
	var cam_pos := cam.global_position

	# Draw area with margin
	var margin := GRID_SIZE * 2
	var top_left := cam_pos - vp_size / 2.0 - Vector2(margin, margin)
	var bottom_right := cam_pos + vp_size / 2.0 + Vector2(margin, margin)

	# Snap to grid
	var start_x: int = int(floorf(top_left.x / GRID_SIZE)) * GRID_SIZE
	var start_y: int = int(floorf(top_left.y / GRID_SIZE)) * GRID_SIZE
	var end_x: int = int(ceilf(bottom_right.x / GRID_SIZE)) * GRID_SIZE
	var end_y: int = int(ceilf(bottom_right.y / GRID_SIZE)) * GRID_SIZE

	# Background fill
	draw_rect(Rect2(top_left, bottom_right - top_left), BG_COLOR)

	# Grid lines
	var x := start_x
	while x <= end_x:
		draw_line(Vector2(x, start_y), Vector2(x, end_y), GRID_COLOR, 1.0)
		x += GRID_SIZE

	var y := start_y
	while y <= end_y:
		draw_line(Vector2(start_x, y), Vector2(end_x, y), GRID_COLOR, 1.0)
		y += GRID_SIZE

	# Dots at intersections + crosses at every 4th intersection
	x = start_x
	while x <= end_x:
		y = start_y
		while y <= end_y:
			var pos := Vector2(x, y)
			var is_major: bool = (x % (GRID_SIZE * 4) == 0) and (y % (GRID_SIZE * 4) == 0)
			if is_major:
				# Cross marker at major intersections
				draw_line(pos + Vector2(-6, 0), pos + Vector2(6, 0), CROSS_COLOR, 2.0)
				draw_line(pos + Vector2(0, -6), pos + Vector2(0, 6), CROSS_COLOR, 2.0)
			else:
				draw_circle(pos, 1.5, DOT_COLOR)
			y += GRID_SIZE
		x += GRID_SIZE
