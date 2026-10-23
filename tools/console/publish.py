"""Uploads: an Android App Bundle to a Google Play track, an iOS build to TestFlight. The
web upload is a placeholder until a host is chosen."""
import os
import subprocess
import sys
from pathlib import Path

from env import path_value
from run import Failure, rel

PACKAGE = "com.dangervalentine.etchinstone"
SCOPE = "https://www.googleapis.com/auth/androidpublisher"
TRACKS = ("internal", "alpha", "beta", "production")


def _play(key: Path):
    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    creds = service_account.Credentials.from_service_account_file(str(key), scopes=[SCOPE])
    return build("androidpublisher", "v3", credentials=creds, cache_discovery=False)


def _play_error(e: Exception) -> str:
    text = str(e)
    if "404" in text or "not found" in text.lower():
        return (f"Play has no app {PACKAGE} that this account can see. The app must exist in Play "
            "Console, and the first build of a new app has to be uploaded there by hand once.")
    if "403" in text or "permission" in text.lower():
        return ("the service account has no permission for this app. In Play Console, Users and "
            "permissions, give its email the Release permission for Dragons of Etchinstone.")
    return text


def play_access_problem(key: Path) -> str | None:
    """None when the key can open an edit on the app (the edit is deleted again), or what
    went wrong. Used by preflight, so a bad key fails before the build, not after it."""
    try:
        edits = _play(key).edits()
        edit = edits.insert(packageName=PACKAGE, body={}).execute()
        edits.delete(packageName=PACKAGE, editId=edit["id"]).execute()
    except Exception as e:
        return f"Google Play refused the key: {_play_error(e)}"
    return None


def upload_android(aab: Path, env: dict, track: str) -> str:
    from googleapiclient.http import MediaFileUpload
    if track not in TRACKS:
        raise Failure(f"track must be one of {TRACKS}")
    # A new app that has never been published accepts only draft releases.
    status = env.get("PLAY_RELEASE_STATUS", "completed")
    edits = _play(path_value(env, "PLAY_SERVICE_ACCOUNT_JSON")).edits()
    try:
        edit = edits.insert(packageName=PACKAGE, body={}).execute()["id"]
        print(f"  Play: uploading {aab.name}")
        bundle = edits.bundles().upload(packageName=PACKAGE, editId=edit,
            media_body=MediaFileUpload(str(aab), mimetype="application/octet-stream", resumable=True)).execute()
        code = str(bundle["versionCode"])
        edits.tracks().update(packageName=PACKAGE, editId=edit, track=track, body={
            "track": track, "releases": [{"versionCodes": [code], "status": status}]}).execute()
        edits.commit(packageName=PACKAGE, editId=edit).execute()
    except Exception as e:
        text = _play_error(e)
        if "draft" in text.lower():
            text += "\nThe app is still a draft in Play Console: set PLAY_RELEASE_STATUS=draft in .env."
        raise Failure(f"Play upload failed: {text}")
    return f"version code {code} on the {track} track ({status})"


def upload_ios(ipa: Path, env: dict, log: Path) -> str:
    if sys.platform != "darwin":
        raise Failure("TestFlight uploads need macOS (Xcode's altool)")
    key = path_value(env, "ASC_KEY_PATH")
    print(f"  TestFlight: uploading {ipa.name}")
    log.parent.mkdir(parents=True, exist_ok=True)
    with open(log, "w") as f:
        code = subprocess.call(["xcrun", "altool", "--upload-app", "--type", "ios", "--file", str(ipa),
            "--apiKey", env["ASC_KEY_ID"], "--apiIssuer", env["ASC_ISSUER_ID"]],
            stdout=f, stderr=subprocess.STDOUT, env={**os.environ, "API_PRIVATE_KEYS_DIR": str(key.parent)})
    if code != 0:
        raise Failure(f"altool upload failed (see {rel(log)})")
    return "uploaded; it shows in TestFlight once Apple has processed it (often 10 to 30 minutes)"


def upload_web(archive: Path, env: dict) -> str:
    print("  Web upload is not implemented yet; the zip is ready to upload by hand.")
    return f"not uploaded: {rel(archive)}"
