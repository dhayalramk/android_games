# Neon Sky Roller 3D

Flagship **solo-leveling** sky highway roller for Android (Godot 4.7 Mobile).

One folder = one game: `games/neon_sky_roller_3d/`

## Why it hooks

- **Tap to roll, drag to steer** — zero learning curve
- **Level 1 → ∞** — each clear unlocks a faster, tighter, meaner skyway
- **Gems + combos** — ascending streak dopamine
- **Boost pads** — FOV warp + speed surge
- **Supernova Fever** — survive ~4.5s clean to go invincible and smash barriers
- **0.2s retry** — wipeout → tap → rolling again

## Controls

| Input | Action |
|---|---|
| Tap | Start / retry / next level |
| Drag L/R | Steer the chrome sphere |

## Levels (solo leveling)

Difficulty scales forever via `scripts/level_config.gd`:

- Longer tracks, higher base speed
- Narrower highways, more gaps & ramps
- Gates, spinning arms, theme shifts (Sunset → Cyber → Magma → Aurora)

Named climbs through Level 10, then Ascension / Overdrive / Solo Level N.

## Run locally

1. Open this folder in **Godot 4.7+**
2. Press Play (`F5`) — mouse drag emulates touch
3. Or export Android preset → install with `scripts/install_to_phone.bat`

## Project layout

```text
neon_sky_roller_3d/
├── project.godot
├── scenes/main.tscn
├── scripts/
│   ├── game_manager.gd   # loop, HUD, save, camera juice
│   ├── player.gd         # ball physics + supernova
│   ├── track.gd          # procedural sky highway
│   ├── level_config.gd   # solo-leveling curve
│   └── spinner.gd        # rotating hazards
└── export_presets.cfg
```
