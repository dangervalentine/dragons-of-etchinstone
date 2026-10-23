"""What each build and upload needs, checked before anything is built or changed. Every
check that fails says what is missing, why it matters and the next step, and all of them
are reported together, so one run shows everything left to set up."""
import json
import os
import plistlib
import re
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

from env import path_value
from run import ROOT, which

GODOT_VERSION = "4.7.2.stable"
HOME = Path.home()


@dataclass
class Check:
    ok: bool
    title: str
    detail: str = ""


def _out(cmd: list[str], env: dict | None = None, merge: bool = True) -> tuple[int, str]:
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, env={**os.environ, **(env or {})}, timeout=120)
        return p.returncode, (p.stdout or "") + ((p.stderr or "") if merge else "")
    except (OSError, subprocess.TimeoutExpired) as e:
        return 1, str(e)


def godot_data_dir() -> Path:
    """Where Godot keeps its export templates and editor settings."""
    if sys.platform == "darwin":
        return HOME / "Library" / "Application Support" / "Godot"
    if os.name == "nt":
        return Path(os.environ.get("APPDATA", HOME / "AppData" / "Roaming")) / "Godot"
    return HOME / ".local" / "share" / "godot"


def editor_setting(key: str) -> str | None:
    """A value from Godot's editor settings, where the editor keeps the Android SDK and
    JDK paths the export uses."""
    path = godot_data_dir() / "editor_settings-4.7.tres"
    if not path.exists():
        return None
    m = re.search(r'^%s = "(.*)"$' % re.escape(key), path.read_text(encoding="utf-8"), re.M)
    # The file escapes backslashes, as Windows paths are written.
    return m.group(1).replace("\\\\", "\\") if m and m.group(1) else None


# --- All platforms -----------------------------------------------------------------

def check_godot() -> list[Check]:
    exe = which("godot")
    if exe is None:
        return [Check(False, "Godot", "`godot` is not on PATH.\n"
            "Install Godot 4.7.2 (standard build) and put a `godot` shim on PATH; see CLAUDE.md.")]
    code, out = _out([exe, "--version"])
    version = out.strip().splitlines()[-1] if out.strip() else ""
    if not version.startswith(GODOT_VERSION):
        return [Check(False, "Godot", f"`godot --version` says {version or 'nothing'!r}; this project needs "
            f"{GODOT_VERSION}. Exports must match the editor the presets were made with.")]
    checks = [Check(True, "Godot", version)]
    templates = godot_data_dir() / "export_templates" / GODOT_VERSION
    if templates.is_dir():
        checks.append(Check(True, "Export templates", str(templates)))
    else:
        checks.append(Check(False, "Export templates", f"None at {templates}.\n"
            "Open the editor, Editor > Manage Export Templates > Download and Install."))
    return checks


# --- Android -----------------------------------------------------------------------

def _java_home() -> Path | None:
    value = editor_setting("export/android/java_sdk_path") or os.environ.get("JAVA_HOME")
    return Path(value) if value else None


def keytool() -> str | None:
    home = _java_home()
    if home:
        for name in ("keytool.exe", "keytool"):
            if (home / "bin" / name).exists():
                return str(home / "bin" / name)
    return which("keytool")


def check_android(env: dict) -> list[Check]:
    checks = []
    sdk = editor_setting("export/android/android_sdk_path") or os.environ.get("ANDROID_HOME")
    if sdk and Path(sdk).is_dir():
        checks.append(Check(True, "Android SDK", sdk))
    else:
        checks.append(Check(False, "Android SDK", "No Android SDK found (Godot's editor setting "
            "export/android/android_sdk_path, or ANDROID_HOME).\nInstall it with Android Studio, then set "
            "the path in Editor > Editor Settings > Export > Android."))
    java = _java_home()
    if java and java.is_dir():
        checks.append(Check(True, "JDK", str(java)))
    else:
        checks.append(Check(False, "JDK", "No JDK 17 found (Godot's editor setting export/android/"
            "java_sdk_path, or JAVA_HOME).\nThe Gradle build that makes the .aab needs it. Install "
            "Temurin 17 and set the path in Editor > Editor Settings > Export > Android."))
    source = godot_data_dir() / "export_templates" / GODOT_VERSION / "android_source.zip"
    if (ROOT / "android" / "build").is_dir():
        checks.append(Check(True, "Android build template", "android/build"))
    elif source.exists():
        checks.append(Check(True, "Android build template", "installed into android/ on the first build"))
    else:
        checks.append(Check(False, "Android build template", f"No {source.name} in the export templates.\n"
            "Reinstall the export templates for 4.7.2 (Editor > Manage Export Templates)."))
    checks.append(check_keystore(env))
    return checks


def check_keystore(env: dict) -> Check:
    title = "Android release keystore"
    missing = [k for k in ("ANDROID_KEYSTORE_PATH", "ANDROID_KEYSTORE_ALIAS", "ANDROID_KEYSTORE_PASSWORD")
        if not env.get(k)]
    if missing:
        return Check(False, title, f"{', '.join(missing)} not set in .env.\n"
            "Store builds must be signed with the same key for the life of the app: Google Play "
            "refuses an update signed with any other. Make one once and back it up:\n"
            "  keytool -genkeypair -v -keystore etchinstone-release.keystore -alias etchinstone \\\n"
            "    -keyalg RSA -keysize 2048 -validity 10000\n"
            "Keep it outside the repository, then set the three keys in .env (see .env.example).")
    path = path_value(env, "ANDROID_KEYSTORE_PATH")
    if not path.exists():
        return Check(False, title, f"ANDROID_KEYSTORE_PATH points at {path}, which does not exist.")
    tool = keytool()
    if tool is None:
        return Check(False, title, "keytool not found, so the keystore cannot be checked. It comes "
            "with the JDK; set Godot's JDK path (see the JDK check).")
    code, out = _out([tool, "-list", "-keystore", str(path), "-alias", env["ANDROID_KEYSTORE_ALIAS"],
        "-storepass:env", "ETCH_STOREPASS"], env={"ETCH_STOREPASS": env["ANDROID_KEYSTORE_PASSWORD"]})
    if code != 0:
        why = "the password is wrong" if "password" in out.lower() else \
            f"there is no key called {env['ANDROID_KEYSTORE_ALIAS']!r} in it" if "alias" in out.lower() else \
            out.strip().splitlines()[-1] if out.strip() else "keytool failed"
        return Check(False, title, f"keytool could not open {path.name}: {why}.\n"
            "List its aliases with: keytool -list -keystore <file>")
    return Check(True, title, f"{path.name}, alias {env['ANDROID_KEYSTORE_ALIAS']}")


def check_play(env: dict) -> list[Check]:
    title = "Google Play service account"
    path = path_value(env, "PLAY_SERVICE_ACCOUNT_JSON")
    if path is None:
        return [Check(False, title, "PLAY_SERVICE_ACCOUNT_JSON not set in .env.\n"
            "In Google Cloud, create a service account and a JSON key for it; in Play Console, "
            "Users and permissions, invite its email with the Release permission for this app. "
            "Then point PLAY_SERVICE_ACCOUNT_JSON at the key file.")]
    if not path.exists():
        return [Check(False, title, f"PLAY_SERVICE_ACCOUNT_JSON points at {path}, which does not exist.")]
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as e:
        return [Check(False, title, f"{path.name} is not valid JSON ({e}).")]
    if data.get("type") != "service_account" or "client_email" not in data:
        return [Check(False, title, f"{path.name} is not a service-account key (no type "
            "\"service_account\" and client_email). Download a JSON key for the account in Google Cloud.")]
    import publish
    problem = publish.play_access_problem(path)
    if problem:
        return [Check(False, title, problem)]
    return [Check(True, title, data["client_email"])]


# --- iOS -----------------------------------------------------------------------------

def profile_dirs() -> list[Path]:
    return [HOME / "Library" / "Developer" / "Xcode" / "UserData" / "Provisioning Profiles",
        HOME / "Library" / "MobileDevice" / "Provisioning Profiles"]


def check_ios(env: dict) -> list[Check]:
    if sys.platform != "darwin":
        return [Check(False, "macOS", "iOS builds need macOS with Xcode; this is "
            f"{sys.platform}. Run the iOS build from the Mac.")]
    checks = []
    if which("xcodebuild"):
        checks.append(Check(True, "Xcode", which("xcodebuild")))
    else:
        checks.append(Check(False, "Xcode", "xcodebuild not found. Install Xcode from the App Store, "
            "then: sudo xcode-select -s /Applications/Xcode.app"))
    uuid = env.get("IOS_PROVISIONING_PROFILE_UUID")
    title = "Provisioning profile"
    if not uuid:
        checks.append(Check(False, title, "IOS_PROVISIONING_PROFILE_UUID not set in .env.\n"
            "In the Apple Developer site, Profiles, make an App Store distribution profile for "
            "com.dangervalentine.etchinstone, download it, open it (Xcode installs it), and put "
            "its UUID in .env (Xcode > Settings > Accounts > Manage Certificates shows it, or "
            "`security cms -D -i <file>`)."))
    else:
        found = [d / f"{uuid}.mobileprovision" for d in profile_dirs() if (d / f"{uuid}.mobileprovision").exists()]
        if not found:
            checks.append(Check(False, title, f"No profile {uuid} installed. Download it from the "
                "Apple Developer site and double-click it."))
        else:
            code, out = _out(["security", "cms", "-D", "-i", str(found[0])], merge=False)
            expires = None
            if code == 0:
                try:
                    expires = plistlib.loads(out.encode("utf-8")).get("ExpirationDate")
                except Exception:
                    pass
            if expires and expires.replace(tzinfo=timezone.utc) < datetime.now(timezone.utc):
                checks.append(Check(False, title, f"Profile {uuid} expired on {expires:%Y-%m-%d}. "
                    "Renew it on the Apple Developer site and install the new one."))
            else:
                checks.append(Check(True, title, uuid))
    code, out = _out(["security", "find-identity", "-v", "-p", "codesigning"])
    if "Apple Distribution" in out:
        checks.append(Check(True, "Distribution certificate", "Apple Distribution in the keychain"))
    else:
        checks.append(Check(False, "Distribution certificate", "No Apple Distribution identity in "
            "the keychain. Xcode > Settings > Accounts > Manage Certificates > + > Apple Distribution."))
    return checks


def check_asc(env: dict) -> list[Check]:
    title = "App Store Connect API key"
    missing = [k for k in ("ASC_KEY_ID", "ASC_ISSUER_ID", "ASC_KEY_PATH") if not env.get(k)]
    if missing:
        return [Check(False, title, f"{', '.join(missing)} not set in .env.\n"
            "In App Store Connect, Users and Access > Integrations > App Store Connect API, make a "
            "key with the App Manager role and download its AuthKey_<id>.p8 (it can be "
            "downloaded only once). Set its key ID, the issuer ID shown above the keys, and the "
            ".p8 path.")]
    path = path_value(env, "ASC_KEY_PATH")
    if not path.exists():
        return [Check(False, title, f"ASC_KEY_PATH points at {path}, which does not exist.")]
    if path.name != f"AuthKey_{env['ASC_KEY_ID']}.p8":
        return [Check(False, title, f"The key file must be named AuthKey_{env['ASC_KEY_ID']}.p8 for "
            f"altool to find it; it is {path.name}. Rename it.")]
    if sys.platform == "darwin" and not which("xcrun"):
        return [Check(False, title, "xcrun not found; the upload uses Xcode's altool.")]
    return [Check(True, title, env["ASC_KEY_ID"])]


# --- Together ------------------------------------------------------------------------

def checks_for(platforms: list[str], upload: list[str], env: dict) -> list[Check]:
    checks = check_godot()
    if "android" in platforms:
        checks += check_android(env)
        if "android" in upload:
            checks += check_play(env)
    if "ios" in platforms:
        checks += check_ios(env)
        if "ios" in upload:
            checks += check_asc(env)
    return checks


def report(checks: list[Check]) -> bool:
    for c in checks:
        print(f"{'  ok ' if c.ok else 'FAIL '} {c.title}" + (f": {c.detail}" if c.ok and c.detail else ""))
        if not c.ok:
            for line in c.detail.splitlines():
                print(f"      {line}")
    failed = [c for c in checks if not c.ok]
    if failed:
        print(f"\n{len(failed)} check(s) failed; nothing was built or changed.")
    return not failed
