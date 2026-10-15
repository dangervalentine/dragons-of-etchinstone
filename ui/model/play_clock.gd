extends RefCounted
## How long a game has been actively played. Advanced once a frame by the real time
## since the previous frame, capped at a second, so a stretch in which the app was
## suspended or hidden adds at most a second however long it lasted.

const MAX_STEP_MS := 1000

var elapsed_ms := 0
var _last := -1


## Advance by the time since the previous call, if the game counts as active.
## A paused call still moves the mark, so resuming never counts the pause.
func tick(now_ms: int, active: bool) -> void:
	if _last >= 0 and active:
		elapsed_ms += clampi(now_ms - _last, 0, MAX_STEP_MS)
	_last = now_ms


## Start again from zero, or from a saved value.
func reset(from_ms := 0) -> void:
	elapsed_ms = from_ms
	_last = -1
