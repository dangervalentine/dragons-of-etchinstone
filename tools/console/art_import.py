"""Bringing reworked art into the game from art/staging/ (specs/018).

The folder a file is in says what kind of art it is, and its name says which picture it
replaces: art/staging/backdrops/naga.png becomes art/painted/backdrops/naga.png.
Illustrator's export numbers are dropped from the name first, so
antler-horror-126-01.png fills antler-horror. The names come from ui/model/art.gd
(through tools/art_slots.gd), so they are always the game's own."""
import difflib
import json
import re
import shutil
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

from run import ROOT, Failure, godot, python, rel, shell

STAGING = ROOT / "art" / "staging"
PAINTED = ROOT / "art" / "painted"
CREATURES = ROOT / "art" / "creatures"
DRAGON_PICTURES = ("", "-full", "-head")


@dataclass(frozen=True)
class Kind:
    folder: str
    one: str  # one of them, for messages
    what: str
    ext: str
    check: str  # figure, scene or rig
    usual: tuple[int, int] | None = None  # a scene's size when there is no picture to compare


KINDS = [
    Kind("enemies", "enemy", "enemy figures (transparent, square)", ".png", "figure"),
    Kind("dragons", "dragon picture", "dragon pictures: <dragon>, <dragon>-full, <dragon>-head", ".png", "figure"),
    Kind("backdrops", "backdrop", "enemy backdrops", ".png", "scene", (1216, 896)),
    Kind("journeys", "journey", "journey maps", ".png", "scene", (768, 1344)),
    Kind("lairs", "lair", "dragon lairs", ".png", "scene", (832, 1152)),
    Kind("roads", "road", "roads to the lairs", ".png", "scene", (832, 1216)),
    Kind("grounds", "ground", "Region grounds: grey, low detail, square (region-jade ...)", ".png", "scene", (512, 512)),
    Kind("rigs", "rig", "dragon layers from Illustrator: <dragon>-parts.svg", ".svg", "rig"),
]
KIND = {k.folder: k for k in KINDS}
# A scene whose shape differs from the one it replaces by more than this loses more of
# its edges to the panel's crop (the game fills the panel, cutting what overflows).
ASPECT_TOLERANCE = 0.10
FIGURE_SIZE = 1024
# Working files kept beside their exports; never imported, and left where they are.
SOURCE_EXTS = (".ai", ".ait")


def load_slots() -> dict:
    """Every name the game draws, by kind: art.gd's lists, read through Godot."""
    log = ROOT / "build" / "logs" / "art-slots.log"
    godot(["-s", "tools/art_slots.gd"], log=log)
    for line in log.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("ART_SLOTS "):
            return json.loads(line[len("ART_SLOTS "):])
    raise Failure(f"tools/art_slots.gd printed no names (see {rel(log)})")


def names_for(kind: str, slots: dict) -> list[str]:
    dragons = slots["dragons"]
    return {
        "enemies": slots["enemies"],
        "dragons": [d + s for d in dragons for s in DRAGON_PICTURES],
        "backdrops": slots["enemies"],
        "journeys": slots["journeys"],
        "lairs": dragons,
        "roads": dragons,
        "rigs": [d + "-parts" for d in dragons],
        "grounds": slots.get("grounds", []),
    }[kind]


def destination(kind: str, name: str) -> Path:
    if kind in ("enemies", "dragons"):
        return PAINTED / f"{name}.png"
    if kind == "rigs":
        return CREATURES / f"{name}.svg"
    return PAINTED / kind / f"{name}.png"


def clean_name(stem: str) -> str:
    """A file name as the slot it fills: lower case, words joined by hyphens, and
    Illustrator's numbers (a seed, an export's -01, a _1_) left out."""
    words = re.split(r"[\s_\-]+", stem.lower())
    return "-".join(w for w in words if w and not w.isdigit())


@dataclass
class Item:
    src: Path
    kind: str | None
    name: str | None = None
    dest: Path | None = None
    old: tuple[int, int] | None = None
    new: tuple[int, int] | None = None
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)


def ensure_staging() -> None:
    """The staging folders, with a .gdignore so Godot never imports what is waiting, and
    a note on the layout."""
    STAGING.mkdir(parents=True, exist_ok=True)
    (STAGING / ".gdignore").touch()
    for k in KINDS:
        (STAGING / k.folder).mkdir(exist_ok=True)
    lines = ["Drop reworked art here, in the folder for its kind, named after what it replaces.",
        "Illustrator's numbers are ignored: antler-horror-126-01.png fills antler-horror.",
        "Illustrator files (.ai) may sit beside their exports; they are skipped and stay here.",
        "Then run: scripts/etch art import", ""]
    lines += [f"  {k.folder + '/':11} {k.what}" for k in KINDS]
    (STAGING / "README.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")


def scan(slots: dict, staging: Path = STAGING) -> list[Item]:
    items = []
    for path in sorted(staging.iterdir()) if staging.exists() else []:
        if path.name.startswith(".") or path.name == "README.txt":
            continue
        if path.is_file():
            items.append(Item(path, None, errors=[f"put it in one of the kind folders: "
                f"{', '.join(k.folder for k in KINDS)}"]))
            continue
        kind = KIND.get(path.name)
        for f in sorted(p for p in path.rglob("*") if p.is_file() and not p.name.startswith(".")
                and p.suffix.lower() not in SOURCE_EXTS):
            if kind is None:
                items.append(Item(f, None, errors=[f"{path.name}/ is not a kind folder; use one of: "
                    f"{', '.join(k.folder for k in KINDS)}"]))
                continue
            item = Item(f, kind.folder)
            items.append(item)
            if f.suffix.lower() != kind.ext:
                item.errors.append(f"{kind.folder} must be {kind.ext} files")
                continue
            name = clean_name(f.stem)
            valid = names_for(kind.folder, slots)
            if name not in valid:
                near = difflib.get_close_matches(name, valid, n=1)
                hint = f" Did you mean {near[0]}?" if near else ""
                item.errors.append(f"no {kind.one} called {name!r}.{hint} "
                    f"Valid: {', '.join(valid)}")
                continue
            item.name, item.dest = name, destination(kind.folder, name)
    seen: dict[Path, Item] = {}
    for item in items:
        if item.dest is None:
            continue
        if item.dest in seen:
            msg = f"two staged files fill {item.name}: {seen[item.dest].src.name} and {item.src.name}"
            item.errors.append(msg)
            seen[item.dest].errors.append(msg)
        seen[item.dest] = item
    return items


def _size(path: Path) -> tuple[int, int]:
    from PIL import Image
    with Image.open(path) as im:
        return im.size


def check(item: Item) -> None:
    """The picture's own checks, against the one it replaces where there is one."""
    if item.errors or item.dest is None:
        return
    kind = KIND[item.kind]
    if kind.check == "rig":
        _check_rig(item)
        return
    from PIL import Image
    try:
        with Image.open(item.src) as im:
            item.new = im.size
            has_alpha = im.mode in ("RGBA", "LA", "PA") or "transparency" in im.info
            transparent = has_alpha and im.convert("RGBA").getchannel("A").getextrema()[0] < 255
    except Exception as e:
        item.errors.append(f"not a readable image ({e})")
        return
    item.old = _size(item.dest) if item.dest.exists() else None
    w, h = item.new
    if kind.check == "figure":
        if w != h:
            item.errors.append(f"must be square (the 512 artboard exported at 2x), not {w}x{h}")
        elif w < FIGURE_SIZE:
            item.errors.append(f"is {w}px; export at {FIGURE_SIZE}px (2x the 512 artboard) or more")
        if not transparent:
            item.errors.append("has no transparency, so it would draw as a box: export with a "
                "transparent background (PNG-24, Transparency on)")
    else:
        ref = item.old or kind.usual
        was, now = ref[0] / ref[1], w / h
        if abs(now - was) / was > ASPECT_TOLERANCE:
            item.warnings.append(f"shape {now:.2f}:1 differs from {was:.2f}:1 "
                f"({ref[0]}x{ref[1]}); the panel's crop will cut more of its edges")


def _check_rig(item: Item) -> None:
    try:
        root = ET.parse(item.src).getroot()
    except ET.ParseError as e:
        item.errors.append(f"is not valid SVG ({e})")
        return
    if (root.get("viewBox") or "").split() != ["0", "0", "512", "512"]:
        item.errors.append(f"must be the 512 x 512 artboard (viewBox is {root.get('viewBox')!r})")
    layers = [re.sub(r"_\d+_$", "", g.get("id") or "") for g in root if g.tag.endswith("}g") or g.tag == "g"]
    if "head" not in layers:
        item.errors.append(f"has no top-level layer called head (layers: {', '.join(l for l in layers if l) or 'none'})")


def preview(items: list[Item]) -> str:
    rows = []
    for i in items:
        what = f"{i.kind}/{i.src.name}" if i.kind else i.src.name
        if i.errors:
            rows.append(f"  ERROR {what}: {'; '.join(i.errors)}")
            continue
        size = ""
        if i.new:
            size = f"  {i.old[0]}x{i.old[1]} -> " if i.old else "  new -> "
            size += f"{i.new[0]}x{i.new[1]}"
        rows.append(f"  {'warn ' if i.warnings else '  ok '} {what}  =>  {rel(i.dest)}{size}")
        for w in i.warnings:
            rows.append(f"        {w}")
    return "\n".join(rows)


def icon_dragon() -> str:
    m = re.search(r'const DEFAULT_DRAGON := "(\w+)"', (ROOT / "tools" / "make_app_icon.gd").read_text(encoding="utf-8"))
    return m.group(1) if m else "grimroch"


def apply(items: list[Item], tests: bool = True) -> list[str]:
    """Copies the good items into the game, re-imports, rebuilds rigs (and the icon when
    its dragon's rig changed), runs the tests for art, and moves the staged files to
    art/staging/.imported/<time>/. Returns what was done, line by line."""
    good = [i for i in items if not i.errors and i.dest]
    done, copied = [], []
    logs = ROOT / "build" / "logs"
    try:
        for i in good:
            i.dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(i.src, i.dest)
            copied.append(i.dest)
    except OSError as e:
        listed = "\n".join(f"  {rel(p)}" for p in copied)
        raise Failure(f"copy stopped at {i.src.name} ({e}). Already copied:\n{listed}\n"
            "Undo with: git checkout -- art/")
    done.append(f"copied {len(copied)} file(s)")
    for i in [i for i in good if i.kind == "rigs"]:
        dragon = i.name[:-len("-parts")]
        code = python("tools/split_rig.py", [rel(i.dest), dragon], log=logs / f"split-rig-{dragon}.log")
        if code != 0:
            raise Failure(f"split_rig.py failed for {dragon} (see build/logs/split-rig-{dragon}.log)")
        done.append(f"rebuilt {dragon}'s rig")
        if dragon == icon_dragon():
            godot(["-s", "tools/make_app_icon.gd", "--", dragon], log=logs / "make-app-icon.log")
            done.append("remade the app icon (its dragon's head changed)")
    godot(["--import"], log=logs / "import.log", check=False)
    done.append("re-imported")
    stamp = datetime.now().strftime("%Y-%m-%d_%H%M%S")
    for i in good:
        target = STAGING / ".imported" / stamp / i.kind / i.src.name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(i.src), target)
    done.append(f"moved the staged files to {rel(STAGING / '.imported' / stamp)}")
    if tests:
        code = shell("tools/test.sh", ["unit", "art", "creature"])
        done.append("unit tests (art, creature): " + ("passed" if code == 0 else "FAILED"))
        code = shell("tools/test.sh", ["ui", "marks", "play"])
        done.append("UI walks (marks, play): " + ("passed" if code == 0 else "FAILED"))
    return done
