# Neon Tac Blitz

Tic-tac-toe — but **not** the boring kind.

One folder = one game: `games/neon_tac_blitz/`

## Why it’s more fun

| Twist | What it does |
|---|---|
| **Blitz clock** | 5 seconds per turn — miss it and you drop randomly |
| **BOMB cells** | Claim → clear adjacent marks |
| **WARP cells** | Claim → place an extra mark |
| **ICE cells** | Claim → mark is locked against bombs |
| **Ult** | Win 2 rounds in a row → place **twice** |
| **Daily gift** | Come back for gems + login streak |

You are **✕** (cyan). AI is **○** (coral).

## Run

```bash
godot --path games/neon_tac_blitz
# or
./scripts/run_neon_tac_blitz.sh
```

Press **S** / Start Blitz. Desktop: Enter rematch after a round.

## Release (Play)

See **[docs/RELEASE.md](docs/RELEASE.md)** and **[PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md)**.

```bash
./scripts/install_android_template.sh
./scripts/build_release_aab.sh   # → build/neon_tac_blitz-release.aab
```

Listing copy: `docs/PLAY_LISTING.md` · Store art: `store/`
