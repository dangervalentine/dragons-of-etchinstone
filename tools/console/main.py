# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "questionary>=2.0",
#     "pillow>=10.0",
#     "google-api-python-client>=2.100",
#     "google-auth>=2.20",
# ]
# ///
"""The project's console (specs/018-dev-console): builds and store uploads, art and the
app icon, installing on devices, tests, and the data generators, from arrow-key menus.

    scripts/etch                         the menus
    scripts/etch build android ios --step patch --upload [--track internal]
    scripts/etch art import [--yes] [--no-tests]      scripts/etch art status
    scripts/etch icon [dragon]
    scripts/etch install android|ios|web|all
    scripts/etch test [quick|full|unit [names]|ui [walks]]
    scripts/etch run | shots | data cards|icons | selftest

Every menu item is one of these commands, so anything done from the menus can be done
from a script too."""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import art_import  # noqa: E402
import build  # noqa: E402
import icon  # noqa: E402
import menu  # noqa: E402
import preflight  # noqa: E402
import publish  # noqa: E402
from env import load_env  # noqa: E402
from run import ROOT, Failure, godot, python, rel, run, shell  # noqa: E402
from version import STEPS, Files  # noqa: E402

PLATFORMS = ("android", "ios", "web")
PLATFORM_LABELS = {"android": "Android (.aab + .apk, Google Play)", "ios": "iOS (.ipa, TestFlight)",
    "web": "Web (.zip; upload not implemented yet)"}
# CLAUDE.md, "Unit tests by area".
UNIT_AREAS = [
    ("Engine: rules, game, card data", ["rules", "game", "card_db", "terms", "playthrough"]),
    ("Card data and flavour", ["card_db", "flavor", "terms", "dragon_stats"]),
    ("View state, turn draft, emphasis", ["view_state", "turn_draft", "emphasis", "terms"]),
    ("Sequencer, board responses, animator", ["sequencer", "board_responses", "deck_stack"]),
    ("Layout solver, window sizer", ["layout_solver", "window_sizer"]),
    ("History, records, clock", ["history_store", "play_history", "play_clock"]),
    ("Rulebook, glossary", ["rulebook", "glossary"]),
    ("Theme, colours, stone", ["card_contrast", "stone_contrast"]),
    ("Art, creatures", ["art", "creature"]),
    ("Lessons, coach mark", ["lessons", "tutorial", "game"]),
]
# CLAUDE.md, "UI check walks".
WALKS = [
    ("notes", "notes on the Deck"), ("screens", "landing, setup, records, rulebook, overlays"),
    ("marks", "effect marks"), ("play", "seeded games through the screens"),
    ("deck", "the reveal, frame by frame (slowest)"), ("skip", "skipping settles as playing"),
    ("look", "zooming out to the Region Card"), ("ending", "a won game's ending"),
    ("resize", "resizing mid-turn"), ("divert", "a Divert, and a refused move"),
    ("arrange", "ordering the Hand"), ("lessons", "Learn to Play"),
]


def say(lines: list[str]) -> None:
    for line in lines:
        print(f"  {line}")


# --- Build & publish -----------------------------------------------------------------

def do_build(platforms: list[str], step: str, upload: list[str], track: str | None, yes: bool) -> int:
    env = load_env()
    track = track or env.get("PLAY_TRACK") or "internal"
    files = Files()
    current = files.read()
    target = current.next(step)
    print(f"\nVersion: {current}  ->  {target}")
    print("Checking what the builds need...\n")
    if not preflight.report(preflight.checks_for(platforms, upload, env)):
        return 1
    if not yes and menu.interactive() and not menu.confirm(
            f"\nBuild {', '.join(platforms)} as {target}?", default=True):
        return 1
    tag = f"{target.version}-{target.build}"
    out = ROOT / "build" / "release" / tag
    files.write(target)
    made: dict[str, list[Path]] = {}
    for p in platforms:
        try:
            made[p] = build.BUILDERS[p](tag, out, env)
        except Failure as e:
            files.restore()
            print(f"\nFAIL {p}: {e}\nThe version is back at {current}.")
            return 1
    print(f"\nBuilt {target} in {rel(out)}:")
    say([rel(f) for files_ in made.values() for f in files_])
    status = 0
    for p in [p for p in platforms if p in upload]:
        try:
            if p == "android":
                result = publish.upload_android(made[p][0], env, track)
            elif p == "ios":
                result = publish.upload_ios(made[p][0], env, out / "logs" / "ios-upload.log")
            else:
                result = publish.upload_web(made[p][0], env)
            print(f"  OK {p} upload: {result}")
        except Failure as e:
            status = 1
            print(f"  FAIL {p} upload: {e}")
    print("\nproject.godot and export_presets.cfg now carry the new version; commit them with the release.")
    return status


def menu_build() -> None:
    platforms = menu.choose_many("Which platforms?", [(PLATFORM_LABELS[p], p) for p in PLATFORMS])
    if not platforms:
        return
    current = Files().read()
    step = menu.choose(f"Version is {current}. Which step?", [
        (f"{s:6} -> {current.next(s)}", s) for s in STEPS])
    if step is None:
        return
    upload = menu.choose_many("Upload after building?", [(f"Upload {p}", p) for p in platforms])
    track = "internal"
    if "android" in upload:
        track = menu.choose("Google Play track?", [(t, t) for t in publish.TRACKS]) or "internal"
    do_build(platforms, step, upload, track, yes=False)


# --- Art & icon --------------------------------------------------------------------------

def do_art(apply: bool, yes: bool, tests: bool) -> int:
    art_import.ensure_staging()
    print("Reading the game's art names...")
    slots = art_import.load_slots()
    items = art_import.scan(slots)
    if not items:
        print(f"Nothing staged. Put files in {rel(art_import.STAGING)}/<kind>/ (see its README.txt).")
        return 0
    for item in items:
        art_import.check(item)
    print(art_import.preview(items))
    good = [i for i in items if not i.errors]
    bad = len(items) - len(good)
    if bad:
        print(f"\n{bad} file(s) with errors will be left in staging.")
    if not apply or not good:
        return 1 if bad else 0
    if menu.interactive() and not yes:
        chosen = menu.choose_many("Bring in which files?", [(f"{i.kind}/{i.src.name}", n)
            for n, i in enumerate(good)], checked=tuple(range(len(good))))
        good = [good[n] for n in chosen]
        if not good or not menu.confirm(f"Copy {len(good)} file(s) into the game?", default=True):
            return 1
    say(art_import.apply(good, tests=tests))
    run(["git", "diff", "--stat", "--", "art/"], check=False)
    return 0


def menu_art() -> None:
    while True:
        choice = menu.choose("Art & icon", [
            ("Import staged art (art/staging/)", "import"),
            ("Check staged art without importing", "status"),
            ("Update the app icon", "icon"),
        ])
        if choice is None:
            return
        try:
            if choice == "icon":
                dragons = art_import.load_slots()["dragons"]
                current = art_import.icon_dragon()
                dragon = menu.choose("Which dragon's head?", [
                    (f"{d}{'  (current)' if d == current else ''}", d) for d in dragons])
                if dragon:
                    say(icon.update_icon(dragon, dragons))
            else:
                do_art(apply=choice == "import", yes=False, tests=True)
        except Failure as e:
            print(f"FAIL: {e}")


# --- Install, tests, data ----------------------------------------------------------------

def menu_install() -> None:
    target = menu.choose("Install a debug build on", [
        ("Android device or emulator", "android"), ("iOS simulator (macOS)", "ios"),
        ("Local web server", "web"), ("All of them", "all")])
    if target:
        shell("scripts/install.sh", [target])


def menu_test() -> None:
    while True:
        choice = menu.choose("Test & run", [
            ("Run the game", "run"),
            ("Quick tests (~1 min)", "quick"),
            ("Full tests (~3 min)", "full"),
            ("Unit tests by area...", "unit"),
            ("UI walks...", "ui"),
            ("Screenshot matrix", "shots"),
        ])
        if choice is None:
            return
        if choice == "run":
            godot([], headless=False, check=False)
        elif choice == "quick":
            shell("tools/test.sh", [])
        elif choice == "full":
            shell("tools/test.sh", ["full"])
        elif choice == "unit":
            areas = menu.choose_many("Which areas?", UNIT_AREAS)
            names = sorted({n for names in areas for n in names})
            if names:
                shell("tools/test.sh", ["unit"] + names)
        elif choice == "ui":
            walks = menu.choose_many("Which walks?", [(f"{w:8} {what}", w) for w, what in WALKS])
            if walks:
                full = menu.confirm("At every window size (slower)?", default=False)
                shell("tools/test.sh", ["ui"] + (["full"] if full else []) + walks)
        elif choice == "shots":
            do_shots()


def do_shots() -> int:
    code = godot(["-s", "tools/shot.gd", "--", "build/screenshots/matrix"], headless=False, check=False)
    print(f"Screenshots in build/screenshots/matrix ({'ok' if code == 0 else 'exit ' + str(code)})")
    return code


def do_data(what: str) -> int:
    if what == "cards":
        code = python("tools/gen_cards.py", ["data/cards.json"])
        if code == 0:
            code = shell("tools/test.sh", ["unit", "card_db", "flavor", "terms", "dragon_stats"])
        return code
    return python("tools/gen_icons.py", [])


def menu_data() -> None:
    what = menu.choose("Regenerate data", [
        ("Card data (tools/gen_cards.py, then its tests)", "cards"),
        ("Icon set in art/icons/ (tools/gen_icons.py)", "icons")])
    if what:
        do_data(what)


def main_menu() -> int:
    branches = {"build": menu_build, "art": menu_art, "install": menu_install,
        "test": menu_test, "data": menu_data}
    while True:
        choice = menu.choose("Dragons of Etchinstone", [
            ("Build & publish", "build"),
            ("Art & icon", "art"),
            ("Install on device", "install"),
            ("Test & run", "test"),
            ("Regenerate data", "data"),
        ], back="Quit")
        if choice is None:
            return 0
        try:
            branches[choice]()
        except Failure as e:
            print(f"FAIL: {e}")
        except KeyboardInterrupt:
            print()


# --- Commands ------------------------------------------------------------------------

def parse(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(prog="etch", description=__doc__.split("\n\n")[0],
        formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="command")
    b = sub.add_parser("build", help="signed release builds, and uploads")
    b.add_argument("platforms", nargs="+", choices=PLATFORMS)
    b.add_argument("--step", choices=STEPS, default="build", help="version step (default: build number only)")
    b.add_argument("--upload", action="store_true", help="upload every platform built")
    b.add_argument("--track", choices=publish.TRACKS, help="Google Play track (default: PLAY_TRACK, or internal)")
    b.add_argument("--yes", action="store_true", help="no confirmation")
    a = sub.add_parser("art", help="import staged art")
    a.add_argument("action", choices=["import", "status"])
    a.add_argument("--yes", action="store_true", help="take every file without asking")
    a.add_argument("--no-tests", action="store_true")
    i = sub.add_parser("icon", help="remake the app icon")
    i.add_argument("dragon", nargs="?")
    inst = sub.add_parser("install", help="debug build on a device (scripts/install.sh)")
    inst.add_argument("target", choices=["android", "ios", "web", "all"])
    t = sub.add_parser("test", help="tools/test.sh")
    t.add_argument("args", nargs="*")
    sub.add_parser("run", help="run the game")
    sub.add_parser("shots", help="screenshot matrix")
    d = sub.add_parser("data", help="regenerate data")
    d.add_argument("what", choices=["cards", "icons"])
    sub.add_parser("selftest", help="the console's own tests")
    return p.parse_args(argv)


def main(argv: list[str]) -> int:
    # Progress shows as it happens even when piped (a log, CI, or the agent's shell).
    sys.stdout.reconfigure(line_buffering=True)
    args = parse(argv)
    try:
        if args.command is None:
            if not menu.interactive():
                print("Not a terminal, so no menus. Commands:\n" + __doc__.split("\n\n")[1])
                return 2
            return main_menu()
        if args.command == "build":
            return do_build(args.platforms, args.step, list(args.platforms) if args.upload else [],
                args.track, args.yes)
        if args.command == "art":
            return do_art(args.action == "import", args.yes, not args.no_tests)
        if args.command == "icon":
            dragons = art_import.load_slots()["dragons"]
            say(icon.update_icon(args.dragon or art_import.icon_dragon(), dragons))
            return 0
        if args.command == "install":
            return shell("scripts/install.sh", [args.target])
        if args.command == "test":
            # tools/test.sh runs the quick tier when given nothing.
            return shell("tools/test.sh", [] if args.args == ["quick"] else args.args)
        if args.command == "run":
            return godot([], headless=False, check=False)
        if args.command == "shots":
            return do_shots()
        if args.command == "data":
            return do_data(args.what)
        if args.command == "selftest":
            return run(["uv", "run", "--with", "pytest", "--with", "pillow", "pytest", "-q",
                "tools/console"], check=False)
    except Failure as e:
        print(f"FAIL: {e}")
        return 1
    except KeyboardInterrupt:
        print()
        return 130
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
