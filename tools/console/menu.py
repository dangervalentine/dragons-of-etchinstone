"""Arrow-key menus through questionary, or numbered menus where it cannot run (Git
Bash's mintty window has no Windows console for it; Windows Terminal and the macOS
Terminal do). Every function returns None, or an empty list, when the menu is left
with Ctrl+C or Back, so callers treat that as going up a level."""
import sys

BACK = "__back__"
_plain = False


def interactive() -> bool:
    return sys.stdin.isatty() and sys.stdout.isatty()


def _questionary(make):
    """Runs a questionary prompt, falling back to numbered menus for the rest of the
    session if the terminal cannot host one."""
    global _plain
    if not _plain:
        try:
            return True, make().ask()
        except Exception as e:  # prompt_toolkit's NoConsoleScreenBufferError, and kin
            _plain = True
            print(f"(arrow-key menus are not available in this terminal: {type(e).__name__}; "
                "using numbered menus. Windows Terminal or `winpty scripts/etch` gives arrow keys.)")
    return False, None


def _number(prompt: str, count: int, allow_many: bool = False) -> list[int] | None:
    while True:
        try:
            raw = input(prompt).strip()
        except (EOFError, KeyboardInterrupt):
            print()
            return None
        if raw == "":
            return None
        try:
            picks = [int(p) for p in raw.replace(",", " ").split()]
        except ValueError:
            picks = []
        if picks and all(1 <= p <= count for p in picks) and (allow_many or len(picks) == 1):
            return [p - 1 for p in picks]
        print(f"  enter {'numbers' if allow_many else 'a number'} from 1 to {count}, or nothing to go back")


def choose(title: str, options: list[tuple[str, object]], back: str = "Back"):
    """One of `options` (label, value), or None for Back."""
    import questionary
    items = options + ([(back, BACK)] if back else [])
    ok, value = _questionary(lambda: questionary.select(title, choices=[
        questionary.Choice(label, value) for label, value in items],
        instruction="(arrows to move, Enter to choose)"))
    if not ok:
        print(f"\n{title}")
        for n, (label, _) in enumerate(items, 1):
            print(f"  {n}. {label}")
        picked = _number("> ", len(items))
        value = items[picked[0]][1] if picked else None
    return None if value == BACK else value


def choose_many(title: str, options: list[tuple[str, object]], checked: tuple = ()) -> list:
    """Any of `options`; empty for none or Back."""
    import questionary
    ok, values = _questionary(lambda: questionary.checkbox(title, choices=[
        questionary.Choice(label, value, checked=value in checked) for label, value in options],
        instruction="(arrows to move, Space to tick, Enter when done)"))
    if not ok:
        print(f"\n{title}")
        for n, (label, _) in enumerate(options, 1):
            print(f"  {n}. {label}")
        picked = _number("numbers, separated by spaces > ", len(options), allow_many=True)
        values = [options[p][1] for p in picked] if picked else []
    return values or []


def confirm(title: str, default: bool = False) -> bool:
    import questionary
    ok, value = _questionary(lambda: questionary.confirm(title, default=default))
    if not ok:
        try:
            raw = input(f"{title} [{'Y/n' if default else 'y/N'}] ").strip().lower()
        except (EOFError, KeyboardInterrupt):
            return False
        value = default if raw == "" else raw in ("y", "yes")
    return bool(value)
