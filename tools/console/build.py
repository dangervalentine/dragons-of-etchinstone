"""Signed release builds, one function per platform, each returning the files it made in
`out` (build/release/<version>/). Signing material reaches Godot only through the
environment variables its exports read, never through the presets on disk."""
import shutil
import sys
from pathlib import Path

from env import path_value
from run import ROOT, Failure, godot, rel

NAME = "dragons-of-etchinstone"


def _export(preset: str, target: Path, log: Path, env: dict | None = None, extra: list[str] | None = None) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        target.unlink()
    # Godot can exit 0 with nothing written (and print errors for harmless things), so
    # the file it was asked for is what decides.
    godot((extra or []) + ["--export-release", preset, str(target)], log=log, env=env, check=False)
    if not target.exists():
        raise Failure(f"the {preset} export produced no {target.name} (see {rel(log)})")


def build_android(version: str, out: Path, env: dict) -> list[Path]:
    signing = {
        "GODOT_ANDROID_KEYSTORE_RELEASE_PATH": str(path_value(env, "ANDROID_KEYSTORE_PATH")),
        "GODOT_ANDROID_KEYSTORE_RELEASE_USER": env["ANDROID_KEYSTORE_ALIAS"],
        "GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD": env["ANDROID_KEYSTORE_PASSWORD"],
    }
    # The Gradle build needs Godot's Android project in android/; it is put there on the
    # first export, and git ignores it.
    extra = [] if (ROOT / "android" / "build").is_dir() else ["--install-android-build-template"]
    aab = out / f"{NAME}-{version}.aab"
    print(f"  Android: {aab.name} (Gradle; the first build downloads Gradle and takes minutes)")
    # Without a daemon: on Windows a Gradle daemon left running holds Godot's handles,
    # and the headless export never exits after writing the bundle.
    gradle = {"GRADLE_OPTS": "-Dorg.gradle.daemon=false"}
    _export("Android Release", aab, out / "logs" / "android-aab.log", {**signing, **gradle}, extra)
    apk = out / f"{NAME}-{version}.apk"
    print(f"  Android: {apk.name}")
    _export("Android", apk, out / "logs" / "android-apk.log", signing)
    return [aab, apk]


def build_ios(version: str, out: Path, env: dict) -> list[Path]:
    if sys.platform != "darwin":
        raise Failure("iOS builds need macOS with Xcode")
    uuid = env["IOS_PROVISIONING_PROFILE_UUID"]
    # Godot 4.7.2 reads the debug variable for the release profile too
    # (editor_export_platform_apple_embedded.cpp), so both carry the release one.
    signing = {
        "GODOT_APPLE_PLATFORM_PROVISIONING_PROFILE_UUID_RELEASE": uuid,
        "GODOT_APPLE_PLATFORM_PROVISIONING_PROFILE_UUID_DEBUG": uuid,
    }
    ipa = out / f"{NAME}-{version}.ipa"
    print(f"  iOS: {ipa.name} (xcodebuild archive; takes minutes)")
    _export("iOS", ipa, out / "logs" / "ios.log", signing)
    return [ipa]


def build_web(version: str, out: Path, env: dict) -> list[Path]:
    folder = out / "web"
    if folder.exists():
        shutil.rmtree(folder)
    print("  Web: export")
    _export("Web", folder / "index.html", out / "logs" / "web.log")
    archive = out / f"{NAME}-web-{version}"
    print(f"  Web: {archive.name}.zip")
    zipped = Path(shutil.make_archive(str(archive), "zip", folder))
    return [zipped]


BUILDERS = {"android": build_android, "ios": build_ios, "web": build_web}
