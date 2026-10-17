extends "res://tests/base.gd"
## The window a desktop game opens in: the largest 16:9 size that fits the monitor
## with its frame, and the least it may be dragged down to.

const WindowSizer = preload("res://ui/model/window_sizer.gd")

## A Windows 11 frame: borders and title bar round the client area.
const DECO := Vector2i(16, 39)


func test_start_size_fits_the_monitor() -> void:
	eq(WindowSizer.start_size(Vector2i(1920, 1032), DECO), Vector2i(1280, 720), "1080p less the taskbar")
	eq(WindowSizer.start_size(Vector2i(2560, 1392), DECO), Vector2i(1920, 1080), "1440p")
	eq(WindowSizer.start_size(Vector2i(3840, 2112), DECO), Vector2i(2560, 1440), "4K")
	eq(WindowSizer.start_size(Vector2i(7680, 4272), DECO), Vector2i(3840, 2160), "8K: the largest size")


func test_start_size_on_a_small_monitor() -> void:
	# 1280 x 720 does not fit under a 728-pixel screen with its title bar, so the
	# window takes the largest 16:9 that does: 689 high.
	eq(WindowSizer.start_size(Vector2i(1366, 728), DECO), Vector2i(1224, 689), "a 1366 x 768 laptop")
	for usable in [Vector2i(1024, 600), Vector2i(1366, 728), Vector2i(800, 1200)]:
		var size := WindowSizer.start_size(usable, DECO)
		ok(absf(float(size.x) / size.y - 16.0 / 9.0) < 0.01, "%s: 16:9" % str(usable))
		ok(size.x + DECO.x <= usable.x and size.y + DECO.y <= usable.y, "%s: fits with its frame" % str(usable))


func test_min_size() -> void:
	eq(WindowSizer.min_size(Vector2i(1280, 720)), Vector2i(960, 540), "no smaller than 960 x 540")
	eq(WindowSizer.min_size(Vector2i(800, 450)), Vector2i(800, 450), "unless the window starts smaller")
