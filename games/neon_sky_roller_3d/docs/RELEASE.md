# Release — Neon Sky Roller 3D (Google Play)

## Versioning

- Source of truth: `VERSION` (semver) + `export_presets.cfg` `version/name` / `version/code`
- Bump both:

```bash
./scripts/set_version.sh 1.0.1
# or auto code from semver, or:
./scripts/set_version.sh 1.0.1 10001
```

Play requires `version/code` to increase on every upload.

## Presets

| Preset | Output | Use |
|---|---|---|
| `Android Debug APK` | `build/neon_sky_roller_3d-debug.apk` | Sideload / QA |
| `Android Release AAB` | `build/neon_sky_roller_3d-release.aab` | Play Console upload |

Release AAB uses **Gradle** (`export_format=1`). Install Android build templates in Godot and point Editor → Export → Android at your SDK.

## Prerequisites

- Godot **4.3+** with Android export templates installed
- Android SDK (`ANDROID_HOME`) + build-tools 34 + platform android-34
- **JDK 17** (Godot Gradle refuses JDK 21+)
- One-time: `./scripts/install_android_template.sh` (creates `android/build`)

## Signing (never commit keystores)

```bash
export NSR_RELEASE_KEYSTORE="/secure/path/nsr-upload.jks"
export NSR_RELEASE_KEYSTORE_USER="upload"
export NSR_RELEASE_KEYSTORE_PASS="***"
export GODOT="/path/to/Godot"
export ANDROID_HOME="$HOME/Android/Sdk"
export JAVA_HOME="/path/to/jdk-17"
./scripts/install_android_template.sh   # once per Godot version
./scripts/build_release_aab.sh
```

Or set the same fields in Godot’s Export dialog for preset **Android Release AAB**.

Create an upload keystore once:

```bash
keytool -genkey -v -keystore nsr-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

## Package identity

- Application ID: `com.dhayalram.neonskyroller3d`
- Display name: Neon Sky Roller 3D
- Min SDK: 24 · Target SDK: 34
- Arch: `arm64-v8a` only (Play 64-bit)

## Upload

1. Build AAB with script above
2. Play Console → Create app / Production or Internal testing
3. Upload `build/neon_sky_roller_3d-release.aab`
4. Attach store listing assets from `store/` (see PRODUCTION_CHECKLIST.md)
