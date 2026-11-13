# Neon Tac Blitz

Tic-tac-toe — but **not** the boring kind.

One folder = one game: `games/neon_tac_blitz/`

## Why it’s more fun

| Twist | What it does |
|---|---|
| **Blitz clock** | 5 seconds per turn — miss it and you drop randomly |
| **💣 Bomb cells** | Claim the cell → clear adjacent marks |
| **🌀 Warp cells** | Claim → place an extra mark somewhere empty |
| **❄ Freeze cells** | Claim → that mark is locked against bombs |
| **Ult** | Win 2 rounds in a row → place **twice** in one turn |

You are **✕** (cyan). AI is **○** (coral). Best of endless rematches.

## Run

1. Open this folder in **Godot 4.3+**
2. Press Play (`F5`) — mouse clicks emulate touch
3. Or: `scripts/run_neon_tac_blitz.bat` / `.sh` from repo root

## Controls

- Tap an empty cell to place
- Tap glowing power badges for chaos effects
- Arm Ult when ready, then place twice

## Layout

```text
neon_tac_blitz/
├── project.godot
├── scenes/main.tscn
├── scripts/
│   ├── game_manager.gd
│   ├── ai.gd
│   ├── sfx.gd
│   └── ui_style.gd
└── README.md
```
