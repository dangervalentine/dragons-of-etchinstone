"""The app icon: made from a dragon's head by tools/make_app_icon.gd, which remembers
the dragon as its DEFAULT_DRAGON so a later rig change remakes the same icon."""
import re

from art_import import icon_dragon
from run import ROOT, Failure, godot, rel

TOOL = ROOT / "tools" / "make_app_icon.gd"
PREVIEW = ROOT / "build" / "icon-preview.png"


def update_icon(dragon: str, dragons: list[str]) -> list[str]:
    if dragon not in dragons:
        raise Failure(f"no dragon called {dragon!r}; one of {', '.join(dragons)}")
    head = ROOT / "art" / "creatures" / f"{dragon}-rig-head-whole.svg"
    if not head.exists():
        raise Failure(f"{rel(head)} is missing; stage {dragon}-parts.svg under art/staging/rigs/ "
            "and import it, or run tools/split_rig.py")
    if dragon != icon_dragon():
        text = TOOL.read_text(encoding="utf-8")
        TOOL.write_bytes(re.sub(r'const DEFAULT_DRAGON := "\w+"', f'const DEFAULT_DRAGON := "{dragon}"',
            text).encode("utf-8"))
    logs = ROOT / "build" / "logs"
    godot(["-s", "tools/make_app_icon.gd", "--", dragon], log=logs / "make-app-icon.log")
    godot(["--import"], log=logs / "import.log", check=False)
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    godot(["-s", "tools/icon_sheet.gd", "--", str(PREVIEW)], log=logs / "icon-sheet.log")
    return [f"icon made from {dragon}'s head (icon.svg, art/launcher/)",
        f"every variant side by side: {rel(PREVIEW)}"]
