"""The credentials in the git-ignored .env (see .env.example). Values are only ever
handed to the commands that need them; nothing here prints or logs them."""
import os
from pathlib import Path

from run import ROOT


def parse(text: str) -> dict[str, str]:
    """KEY=value lines; blank lines and # comments skipped, `export ` and matching quotes
    removed. An empty value counts as not set."""
    out = {}
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        if line.startswith("export "):
            line = line[len("export "):]
        key, value = line.split("=", 1)
        key, value = key.strip(), value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "'\"":
            value = value[1:-1]
        if value:
            out[key] = value
    return out


def load_env(path: Path | None = None) -> dict[str, str]:
    """The .env values, with the process environment taking precedence, so a CI job can
    set them without a file."""
    path = path or ROOT / ".env"
    values = parse(path.read_text(encoding="utf-8")) if path.exists() else {}
    for key in list(values) + [k for k in os.environ if k not in values]:
        if os.environ.get(key):
            values[key] = os.environ[key]
    return values


def path_value(env: dict[str, str], key: str) -> Path | None:
    """A path from .env, relative ones taken from the project folder, ~ expanded."""
    value = env.get(key)
    if not value:
        return None
    p = Path(os.path.expanduser(value))
    return p if p.is_absolute() else ROOT / p
