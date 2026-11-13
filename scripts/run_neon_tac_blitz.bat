@echo off
REM Launch Neon Tac Blitz in Godot (set GODOT if needed)
cd /d "%~dp0\..\games\neon_tac_blitz"
if "%GODOT%"=="" (
  echo Set GODOT to your Godot 4.x exe, then re-run.
  exit /b 1
)
"%GODOT%" --path .
