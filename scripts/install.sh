#!/bin/sh
# Build the game and put it on the running Android emulator and/or iOS simulator,
# or serve the web build locally.
#
#   install.sh [android|ios|web|all]      (default: all = android + ios + web)
#
# Environment:
#   ANDROID_SERIAL  adb device to use (default: the first one that is online)
#   IOS_SIM         simulator UDID to use (default: the first booted iPhone)
#   WEB_PORT        port for the local web server (default: 8765)
#
# Each platform ends with one line starting OK, SKIP or FAIL. Exit status is
# non-zero if any requested platform failed or had no device to install on.

APP_ID="com.dangervalentine.etchinstone"
NAME="dragons-of-etchinstone"
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || exit 1
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export JAVA_HOME="${JAVA_HOME:-$(/usr/libexec/java_home -v 17 2>/dev/null)}"
ADB="$ANDROID_HOME/platform-tools/adb"
SHOTS="$ROOT/build/screenshots"
LOGS="$ROOT/build/logs"
mkdir -p "$SHOTS" "$LOGS"
touch "$ROOT/build/.gdignore"
status=0

# Godot prints harmless errors about preset sections; a real failure leaves no output file.
export_preset() {
	godot --headless --path "$ROOT" --export-debug "$1" > "$LOGS/export-$2.log" 2>&1
}

android() {
	serial="${ANDROID_SERIAL:-$("$ADB" devices | awk 'NR>1 && $2=="device" {print $1; exit}')}"
	if [ -z "$serial" ]; then
		echo "SKIP android: no emulator or device is online. Available emulators:"
		"$ANDROID_HOME/emulator/emulator" -list-avds 2>/dev/null | sed 's/^/    /'
		return 1
	fi
	apk="build/android/$NAME.apk"
	rm -f "$apk"
	mkdir -p build/android
	export_preset Android android
	if [ ! -f "$apk" ]; then
		echo "FAIL android: export produced no APK (see build/logs/export-android.log)"
		return 1
	fi
	if ! "$ADB" -s "$serial" install -r "$apk" > "$LOGS/install-android.log" 2>&1; then
		echo "FAIL android: install on $serial failed (see build/logs/install-android.log)"
		return 1
	fi
	"$ADB" -s "$serial" shell am force-stop "$APP_ID"
	"$ADB" -s "$serial" shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
	sleep 6
	if [ -z "$("$ADB" -s "$serial" shell pidof "$APP_ID")" ]; then
		echo "FAIL android: installed on $serial but the app is not running after launch"
		return 1
	fi
	"$ADB" -s "$serial" exec-out screencap -p > "$SHOTS/android.png"
	echo "OK android: running on $serial, screenshot at build/screenshots/android.png"
}

ios() {
	sim="${IOS_SIM:-$(xcrun simctl list devices booted | awk -F '[()]' '/iPhone/ {print $(NF-3); exit}')}"
	if [ -z "$sim" ]; then
		echo "SKIP ios: no iPhone simulator is booted. Available simulators:"
		xcrun simctl list devices available | grep -E '^--|iPhone' | sed 's/^/    /'
		return 1
	fi
	rm -rf build/ios-sim
	mkdir -p build/ios-sim
	export_preset "iOS Simulator" ios
	proj="build/ios-sim/$NAME.xcodeproj"
	if [ ! -d "$proj" ]; then
		echo "FAIL ios: export produced no Xcode project (see build/logs/export-ios.log)"
		return 1
	fi
	lib="build/ios-sim/$NAME.xcframework/ios-arm64_x86_64-simulator/libgodot.a"
	if ! lipo -archs "$lib" 2>/dev/null | grep -q arm64; then
		echo "FAIL ios: the Godot export template has no Apple Silicon simulator library."
		echo "    See .claude/skills/install-on-emulators/references/ios-simulator-template.md"
		return 1
	fi
	if ! xcodebuild -project "$proj" -scheme "$NAME" -configuration Debug -sdk iphonesimulator \
		-destination "id=$sim" -derivedDataPath build/ios-sim/dd CODE_SIGNING_ALLOWED=NO build \
		> "$LOGS/xcodebuild-ios.log" 2>&1; then
		echo "FAIL ios: xcodebuild failed (see build/logs/xcodebuild-ios.log)"
		return 1
	fi
	app="build/ios-sim/dd/Build/Products/Debug-iphonesimulator/$NAME.app"
	if ! xcrun simctl install "$sim" "$app" > "$LOGS/install-ios.log" 2>&1; then
		echo "FAIL ios: install on $sim failed (see build/logs/install-ios.log)"
		return 1
	fi
	xcrun simctl terminate "$sim" "$APP_ID" > /dev/null 2>&1
	if ! xcrun simctl launch "$sim" "$APP_ID" >> "$LOGS/install-ios.log" 2>&1; then
		echo "FAIL ios: installed on $sim but launch failed (see build/logs/install-ios.log)"
		return 1
	fi
	sleep 6
	if ! xcrun simctl spawn "$sim" launchctl list | grep -q "$APP_ID"; then
		echo "FAIL ios: launched on $sim but the app is no longer running"
		return 1
	fi
	xcrun simctl io "$sim" screenshot "$SHOTS/ios.png" > /dev/null 2>&1
	name=$(xcrun simctl list devices | grep "$sim" | sed 's/ (.*//; s/^ *//')
	echo "OK ios: running on $name ($sim), screenshot at build/screenshots/ios.png"
}

web() {
	port="${WEB_PORT:-8765}"
	rm -rf build/web
	mkdir -p build/web
	export_preset Web web
	if [ ! -f build/web/index.html ] || [ ! -f build/web/index.pck ]; then
		echo "FAIL web: export produced no web build (see build/logs/export-web.log)"
		return 1
	fi
	# Serve without caching, so a reload always shows the build just exported.
	if ! lsof -nP -iTCP:"$port" -sTCP:LISTEN > /dev/null 2>&1; then
		nohup python3 -I -c '
import http.server, sys
class H(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()
    def log_message(self, *a):
        pass
http.server.ThreadingHTTPServer(("127.0.0.1", int(sys.argv[1])), lambda *a: H(*a, directory=sys.argv[2])).serve_forever()
' "$port" "$ROOT/build/web" > "$LOGS/web-server.log" 2>&1 &
		sleep 1
	fi
	if ! curl -fs -o /dev/null "http://127.0.0.1:$port/index.pck"; then
		echo "FAIL web: nothing is serving the build on port $port (see build/logs/web-server.log)"
		return 1
	fi
	echo "OK web: http://127.0.0.1:$port/index.html (local only; reload the page to see this build)"
}

case "${1:-all}" in
	android) android || status=1 ;;
	ios) ios || status=1 ;;
	web) web || status=1 ;;
	all) android || status=1; ios || status=1; web || status=1 ;;
	*) echo "usage: install.sh [android|ios|web|all]"; exit 2 ;;
esac
exit $status
