@echo off
REM Export signed Play Store AAB (Windows).
REM Set GODOT to Godot.exe, ANDROID_HOME to SDK, and NSR_RELEASE_KEYSTORE* for signing.
setlocal
cd /d "%~dp0\.."
if "%GODOT%"=="" (
  echo ERROR: set GODOT to Godot 4.x exe path
  exit /b 1
)
if not "%NSR_VERSION%"=="" (
  bash scripts\set_version.sh %NSR_VERSION%
)
if not exist build mkdir build
"%GODOT%" --headless --path . --export-release "Android Release AAB" "build\neon_sky_roller_3d-release.aab"
if errorlevel 1 exit /b %errorlevel%
dir build\neon_sky_roller_3d-release.aab
echo OK: build\neon_sky_roller_3d-release.aab
endlocal
