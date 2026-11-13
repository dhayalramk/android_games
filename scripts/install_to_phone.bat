@echo off
echo ========================================================
echo  Installing Stack Smash 3D to connected Android device
echo ========================================================
echo Checking ADB connection...
adb devices
echo.
echo Installing APK...
adb install -r "%~dp0..\games\stack_smash_3d\build\stack_smash_3d.apk"
if %errorlevel% equ 0 (
    echo.
    echo Launching Stack Smash 3D on phone...
    adb shell am start -n com.dhayalram.stacksmash3d/com.godot.game.GodotApp
    echo Success! Game is now running on your phone.
) else (
    echo.
    echo [ERROR] Could not install. Please make sure:
    echo 1. Your phone screen is unlocked.
    echo 2. USB Debugging is enabled in Developer Options.
    echo 3. You tapped "Allow USB Debugging" on the phone prompt.
)
pause
