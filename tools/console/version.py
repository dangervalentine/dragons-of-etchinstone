"""The game's version and build number, kept where Godot's exports read them.

The version (1.4.2) is `application/config/version` in project.godot; Android's
`version/name` and iOS's `application/short_version` are left empty so they follow it.
The build number is `version/code` in both Android presets and `application/version` in
the iOS preset, and goes up on every release build: both stores refuse one they have
seen, whatever the version."""
from dataclasses import dataclass
from pathlib import Path

import cfg
from run import ROOT

STEPS = ("build", "patch", "minor", "major")
ANDROID_PRESETS = ("Android", "Android Release")
IOS_PRESETS = ("iOS",)


@dataclass(frozen=True)
class Version:
    version: str
    build: int

    def next(self, step: str) -> "Version":
        if step not in STEPS:
            raise ValueError(f"step must be one of {STEPS}, not {step!r}")
        major, minor, patch = (int(p) for p in self.version.split("."))
        if step == "major":
            major, minor, patch = major + 1, 0, 0
        elif step == "minor":
            minor, patch = minor + 1, 0
        elif step == "patch":
            patch += 1
        return Version(f"{major}.{minor}.{patch}", self.build + 1)

    def __str__(self) -> str:
        return f"{self.version} (build {self.build})"


class Files:
    """project.godot and export_presets.cfg, read once, so a failed build can put back
    exactly the text that was there."""

    def __init__(self, root: Path = ROOT):
        self.project = root / "project.godot"
        self.presets = root / "export_presets.cfg"
        self.saved = {p: p.read_bytes() for p in (self.project, self.presets)}

    def read(self) -> Version:
        project = self.saved[self.project].decode("utf-8")
        presets = self.saved[self.presets].decode("utf-8")
        version = cfg.unquote(cfg.get(project, "application", "config/version")) or "0.0.0"
        parts = (version.split(".") + ["0", "0"])[:3]
        version = ".".join(str(int(p)) if p.isdigit() else "0" for p in parts)
        builds = [0]
        for name, key in [(n, "version/code") for n in ANDROID_PRESETS] + \
                [(n, "application/version") for n in IOS_PRESETS]:
            section = cfg.preset_options(presets, name)
            value = cfg.unquote(cfg.get(presets, section, key)) if section else None
            if value and value.isdigit():
                builds.append(int(value))
        return Version(version, max(builds))

    def write(self, v: Version) -> None:
        project = self.project.read_text(encoding="utf-8")
        project = cfg.set(project, "application", "config/version", f'"{v.version}"')
        presets = self.presets.read_text(encoding="utf-8")
        for name in ANDROID_PRESETS:
            if section := cfg.preset_options(presets, name):
                presets = cfg.set(presets, section, "version/code", str(v.build))
        for name in IOS_PRESETS:
            if section := cfg.preset_options(presets, name):
                presets = cfg.set(presets, section, "application/version", f'"{v.build}"')
        self.project.write_bytes(project.encode("utf-8"))
        self.presets.write_bytes(presets.encode("utf-8"))

    def restore(self) -> None:
        for path, data in self.saved.items():
            path.write_bytes(data)
