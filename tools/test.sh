#!/bin/sh
# Runs the tests headless. Script errors count as failures. Godot's own report of
# objects still allocated at exit (leaks, resources still in use) is not an error in
# the game and is ignored.
#
#   tools/test.sh                 quick: the unit tests, then the UI check once at
#                                 the smallest phone (about a minute)
#   tools/test.sh full            everything: the UI check at every window size in
#                                 the layout matrix (about three and a half minutes);
#                                 run it before a commit
#   tools/test.sh unit [name ...] the unit tests only, or only the test_*.gd files
#                                 whose names contain a name given (seconds)
#   tools/test.sh ui [full] [walk ...]
#                                 the UI check only, or only the walks named:
#                                 notes screens marks play deck skip look ending
#                                 resize divert arrange lessons
cd "$(dirname "$0")/.." || exit 1

errors() {
	echo "$1" | grep -E 'SCRIPT ERROR|^ERROR|Parse Error' | grep -v 'leaked' | grep -qv 'still in use at exit'
}

unit() {
	out=$(godot --headless --path . -s tests/run.gd -- "$@" 2>&1)
	status=$?
	echo "$out" | grep -v '^Godot Engine' | grep -v '^$'
	if errors "$out"; then
		echo "script errors in output"
		return 1
	fi
	return $status
}

ui() {
	out=$(godot --headless --path . -s tools/ui_check.gd -- "$@" 2>&1)
	status=$?
	echo "$out" | grep -E '^FAIL|^ui check|SCRIPT ERROR|^ERROR' | grep -v 'leaked' | grep -v 'still in use at exit'
	if errors "$out"; then
		echo "script errors in output"
		return 1
	fi
	return $status
}

case "$1" in
	unit) shift; unit "$@" ;;
	ui) shift; ui "$@" ;;
	full) unit && ui full ;;
	"") unit && ui ;;
	*) echo "usage: tools/test.sh [full | unit [name ...] | ui [full] [walk ...]]"; exit 2 ;;
esac
