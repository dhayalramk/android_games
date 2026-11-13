# Neon Sky Roller 3D

Flagship **solo-leveling** sky highway roller for Android (Godot 4.7 Mobile).

One folder = one game: `games/neon_sky_roller_3d/`

## Why people keep coming back

| Hook | Why it works |
|---|---|
| **Daily Gift + login streak** | Come back tomorrow for gems; miss a day and the streak resets |
| **Daily Mission** | One clear goal every day (clears / gems / ★★★ / turbo / supernova) |
| **Solo Rank (XP)** | Permanent power-fantasy climb — every clear feeds your rank |
| **★★★ Mastery** | Replay earlier levels for perfect stars |
| **Ball Garage** | Spend gems on Cyber / Chrome / Solar / Dark Matter / Aurora / Crimson |
| **Comeback bonus** | Away 2+ days? Extra gem gift when you return |

Plus the core loop: level 1→∞, turbo/brake control, Supernova smash, instant retry.

## Controls

| Input | Action |
|---|---|
| Tap | Start / retry / next level |
| Drag ← → | Steer the chrome sphere |
| Drag ↑ | **Turbo** — player-controlled speed boost |
| Drag ↓ | **Brake** — slow down for tight gates |
| Boost pads / Supernova | Extra speed on top of your throttle |

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
