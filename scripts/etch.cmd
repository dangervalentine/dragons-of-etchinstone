@echo off
rem The project console for cmd and PowerShell; see scripts/etch.
uv run --quiet --script "%~dp0..\tools\console\main.py" %*
