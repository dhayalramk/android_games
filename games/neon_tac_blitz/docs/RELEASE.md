# Release — Neon Tac Blitz

## Package

- Application ID: `com.dhayalram.neontacblitz`
- Version: see `VERSION` + `export_presets.cfg`
- Min SDK 24 · Target 34 · arm64-v8a
- JDK **17** required for Gradle AAB

## Build

```bash
./scripts/install_android_template.sh   # once per Godot version
export GODOT=... ANDROID_HOME=... JAVA_HOME=.../jdk-17
export NSR_RELEASE_KEYSTORE=... NSR_RELEASE_KEYSTORE_USER=... NSR_RELEASE_KEYSTORE_PASS=...
# (env names reused from studio scripts — or set keystore in Godot Export UI)
./scripts/build_release_aab.sh
```

Output: `build/neon_tac_blitz-release.aab`

## Version bump

```bash
./scripts/set_version.sh 1.0.1
```
