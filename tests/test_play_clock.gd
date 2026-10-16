extends "res://tests/base.gd"
## Active play time: summed frame times, only while active, never a long gap.

const PlayClock = preload("res://ui/model/play_clock.gd")


func test_active_ticks_add_up() -> void:
	var c = PlayClock.new()
	c.tick(1000, true)
	c.tick(1016, true)
	c.tick(1032, true)
	eq(c.elapsed_ms, 32, "two frames of 16 ms")


func test_the_first_tick_adds_nothing() -> void:
	var c = PlayClock.new()
	c.tick(50000, true)
	eq(c.elapsed_ms, 0, "nothing before the first frame")


func test_inactive_ticks_add_nothing() -> void:
	var c = PlayClock.new()
	c.tick(0, true)
	c.tick(500, false)
	c.tick(900, false)
	eq(c.elapsed_ms, 0, "paused")


func test_a_long_gap_adds_at_most_a_second() -> void:
	var c = PlayClock.new()
	c.tick(0, true)
	c.tick(600000, true)
	eq(c.elapsed_ms, 1000, "a suspended app counts one second at most")


func test_resuming_does_not_count_the_pause() -> void:
	var c = PlayClock.new()
	c.tick(0, true)
	c.tick(100, true)
	for t in range(200, 10200, 100):
		c.tick(t, false)
	c.tick(10200, true)
	c.tick(10300, true)
	eq(c.elapsed_ms, 300, "100 before, 100 on resuming, 100 after")


func test_reset_starts_again() -> void:
	var c = PlayClock.new()
	c.tick(0, true)
	c.tick(400, true)
	c.reset()
	eq(c.elapsed_ms, 0, "back to zero")
	c.tick(9000, true)
	eq(c.elapsed_ms, 0, "the first tick after a reset adds nothing")
	c.reset(5000)
	eq(c.elapsed_ms, 5000, "from a saved value")
