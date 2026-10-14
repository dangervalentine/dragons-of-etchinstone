#!/bin/sh
# Runs the engine tests headless. Script errors count as failures.
cd "$(dirname "$0")/.." || exit 1
out=$(godot --headless --path . -s tests/run.gd 2>&1)
status=$?
echo "$out" | grep -v '^Godot Engine' | grep -v '^$'
if echo "$out" | grep -qE 'SCRIPT ERROR|^ERROR|Parse Error'; then
	echo "script errors in output"
	exit 1
fi
exit $status
