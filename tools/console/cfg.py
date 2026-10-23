"""Reading and setting keys in Godot's config text (project.godot, export_presets.cfg)
without disturbing anything else in it, so the editor's own formatting survives. Lines
may end in CRLF (a file saved by a Windows tool); a changed line keeps its ending."""
import re

SECTION = re.compile(r"^\[(.+)\]\s*$")
CR = "\r"


def _sections(lines: list[str]) -> list[tuple[str, int, int]]:
    """(name, first line, end line) of each section; end is where the next begins."""
    starts = [(m.group(1), i) for i, line in enumerate(lines) if (m := SECTION.match(line))]
    out = []
    for n, (name, start) in enumerate(starts):
        end = starts[n + 1][1] if n + 1 < len(starts) else len(lines)
        out.append((name, start, end))
    return out


def get(text: str, section: str, key: str) -> str | None:
    """The raw value (quotes kept) of `key` in `[section]`, or None."""
    lines = text.split("\n")
    for name, start, end in _sections(lines):
        if name == section:
            for line in lines[start + 1:end]:
                if line.startswith(key + "="):
                    return line[len(key) + 1:].rstrip(CR)
    return None


def unquote(value: str | None) -> str | None:
    if value is not None and len(value) >= 2 and value[0] == value[-1] == '"':
        return value[1:-1]
    return value


def set(text: str, section: str, key: str, value: str) -> str:
    """`text` with `key=value` in `[section]`: replaced where it is, otherwise added after
    the section's last key. `value` is written as given (quote strings yourself). A
    missing section is added at the end."""
    lines = text.split("\n")
    for name, start, end in _sections(lines):
        if name != section:
            continue
        last = start
        for i in range(start + 1, end):
            if lines[i].startswith(key + "="):
                lines[i] = f"{key}={value}" + (CR if lines[i].endswith(CR) else "")
                return "\n".join(lines)
            if lines[i].strip() and not lines[i].startswith(";"):
                last = i
        lines.insert(last + 1, f"{key}={value}" + (CR if lines[last].endswith(CR) else ""))
        return "\n".join(lines)
    tail = "" if text.endswith("\n\n") else ("\n" if text.endswith("\n") else "\n\n")
    return text + tail + f"[{section}]\n\n{key}={value}\n"


def preset_options(text: str, preset_name: str) -> str | None:
    """The options section (`preset.N.options`) of the export preset called `preset_name`."""
    lines = text.split("\n")
    for name, start, end in _sections(lines):
        if re.fullmatch(r"preset\.\d+", name):
            for line in lines[start + 1:end]:
                if line.rstrip(CR) == f'name="{preset_name}"':
                    return name + ".options"
    return None
