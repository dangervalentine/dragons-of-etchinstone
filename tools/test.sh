#!/bin/sh
# Runs the tests headless: the rules engine and UI model tests, then the UI check,
# which plays seeded games through the real screens at every window size.
# Script errors count as failures. Godot's own report of objects still allocated
# at exit is not an error in the game and is ignored.
cd "$(dirname "$0")/.." || exit 1

errors() {
	echo "$1" | grep -E 'SCRIPT ERROR|^ERROR|Parse Error' | grep -qv 'leaked'
}

out=$(godot --headless --path . -s tests/run.gd 2>&1)
status=$?
echo "$out" | grep -v '^Godot Engine' | grep -v '^$'
if errors "$out"; then
	echo "script errors in output"
	exit 1
fi
[ $status -eq 0 ] || exit $status

out=$(godot --headless --path . -s tools/ui_check.gd 2>&1)
status=$?
echo "$out" | grep -E '^FAIL|^ui check|SCRIPT ERROR|^ERROR' | grep -v 'leaked'
if errors "$out"; then
	echo "script errors in output"
	exit 1
fi
exit $status
