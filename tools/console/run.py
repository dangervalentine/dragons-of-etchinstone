"""Running the project's commands: Godot, the shell scripts and the Python tools, each
either straight to the terminal or into a log, with a failure that names its log."""
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class Failure(Exception):
    """A step that could not be done. The message says what went wrong and, where
    there is one, which log holds the details."""


def which(name: str) -> str | None:
    return shutil.which(name)


def run(cmd: list[str], log: Path | None = None, env: dict | None = None, check: bool = True) -> int:
    """Runs `cmd` in the project folder. With `log`, its output goes there and only a
    failure is reported; without, it goes to the terminal as it comes."""
    full_env = dict(os.environ)
    if env:
        full_env.update(env)
    if log is None:
        code = subprocess.call(cmd, cwd=ROOT, env=full_env)
    else:
        log.parent.mkdir(parents=True, exist_ok=True)
        with open(log, "w", encoding="utf-8", errors="replace") as f:
            code = subprocess.call(cmd, cwd=ROOT, env=full_env, stdout=f, stderr=subprocess.STDOUT)
    if check and code != 0:
        where = f" (see {rel(log)})" if log else ""
        raise Failure(f"{Path(cmd[0]).name} {' '.join(cmd[1:3])} ... exited with {code}{where}")
    return code


def godot_exe() -> str:
    exe = which("godot")
    if exe is None:
        raise Failure("godot is not on PATH. Install Godot 4.7.2 and put a `godot` shim on PATH "
            "(see CLAUDE.md, Commands).")
    return exe


def godot(args: list[str], log: Path | None = None, env: dict | None = None, headless: bool = True,
        check: bool = True) -> int:
    cmd = [godot_exe()] + (["--headless"] if headless else []) + ["--path", str(ROOT)] + args
    return run(cmd, log=log, env=env, check=check)


def shell(script: str, args: list[str], log: Path | None = None) -> int:
    """A project shell script, through bash where there is one (Git Bash on Windows)."""
    # Git's own bash first: from PowerShell, the bash on PATH can be WSL's.
    git_bash = Path(os.environ.get("ProgramFiles", r"C:\Program Files")) / "Git" / "bin" / "bash.exe"
    sh = str(git_bash) if os.name == "nt" and git_bash.exists() else which("bash") or which("sh")
    if sh is None:
        raise Failure("no bash or sh found; on Windows, run this from Git Bash or install Git for Windows")
    return run([sh, script] + args, log=log, check=False)


def python(script: str, args: list[str], log: Path | None = None) -> int:
    return run([sys.executable, script] + args, log=log, check=False)


def rel(p: Path | str) -> str:
    try:
        return Path(p).resolve().relative_to(ROOT).as_posix()
    except ValueError:
        return str(p)


def tail(log: Path, lines: int = 15) -> str:
    try:
        return "\n".join(log.read_text(encoding="utf-8", errors="replace").splitlines()[-lines:])
    except OSError:
        return ""
