#!/usr/bin/env bash
# Builds trimmed release export templates from Godot's source (CLAUDE.md, "Release size").
# The class list comes from tools/engine.gdbuild. Every engine module is off except the
# ones the game uses when it runs:
#   gdscript, freetype (fonts), svg (ui/fx/creature.gd), webp (painted art),
#   regex, noise (unused since specs/019 removed ui/theme/stone.gd; drop it at the
#   next template rebuild), text_server_adv.
# Usage: tools/build_templates.sh <web|ios|android|windows> [godot source dir]
set -euo pipefail

platform="${1:?usage: tools/build_templates.sh <web|ios|android|windows> [godot source dir]}"
repo="$(cd "$(dirname "$0")/.." && pwd)"
src="${2:-$HOME/dev/godot}"

common=(
	target=template_release production=yes optimize=size
	"build_profile=$repo/tools/engine.gdbuild"
	modules_enabled_by_default=no
	module_gdscript_enabled=yes module_freetype_enabled=yes module_svg_enabled=yes
	module_webp_enabled=yes module_regex_enabled=yes module_noise_enabled=yes
	module_text_server_adv_enabled=yes
)

cd "$src"
case "$platform" in
	web)
		# The Web preset has thread_support=false, so it needs the nothreads template.
		source "${EMSDK:-$HOME/dev/emsdk}/emsdk_env.sh" >/dev/null
		scons platform=web threads=no "${common[@]}"
		;;
	ios)
		# Simulator and device libraries, then the Xcode project bundle (bin/godot_ios.zip).
		scons platform=ios arch=arm64 simulator=yes "${common[@]}"
		scons platform=ios arch=arm64 generate_bundle=yes "${common[@]}"
		# The iOS exporter always links MoltenVK.xcframework, but this build has no
		# Vulkan, so the bundle gets an empty stand-in instead of the 7 MB library.
		tmp="$(mktemp -d)"
		echo 'void godot_no_moltenvk(void) {}' > "$tmp/stub.c"
		xcrun -sdk iphoneos clang -arch arm64 -mios-version-min=14.0 -c "$tmp/stub.c" -o "$tmp/dev.o"
		xcrun -sdk iphonesimulator clang -arch arm64 -mios-simulator-version-min=14.0 -c "$tmp/stub.c" -o "$tmp/sim.o"
		mkdir -p "$tmp/dev" "$tmp/sim" "$tmp/bundle"
		libtool -static -o "$tmp/dev/libMoltenVK.a" "$tmp/dev.o"
		libtool -static -o "$tmp/sim/libMoltenVK.a" "$tmp/sim.o"
		xcodebuild -create-xcframework -library "$tmp/dev/libMoltenVK.a" -library "$tmp/sim/libMoltenVK.a" \
			-output "$tmp/bundle/MoltenVK.xcframework" >/dev/null
		(cd "$tmp/bundle" && zip -qr "$src/bin/godot_ios.zip" MoltenVK.xcframework)
		rm -rf "$tmp"
		;;
	android)
		scons platform=android arch=arm64 generate_android_binaries=yes "${common[@]}"
		;;
	windows)
		scons platform=windows arch=x86_64 d3d12=no vulkan=no angle=yes "${common[@]}"
		;;
	*)
		echo "unknown platform: $platform" >&2
		exit 1
		;;
esac
