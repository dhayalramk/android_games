# Neon Sky Roller 3D — Production Readiness Checklist

Goal: shippable Google Play closed/open release.

## Status

| # | Item | Status |
|---|---|---|
| 1 | Stable hub / input / gameplay entry | DONE |
| 2 | Release Android export (.aab) + versioning + build scripts | DONE |
| 3 | Store assets (adaptive icon, feature graphic, screenshots) | TODO |
| 4 | Privacy policy + Play data-safety stubs | TODO |
| 5 | Device QA / install test scripts | TODO |
| 6 | Production audio (music + real SFX) | TODO |
| 7 | Visual quality at commercial mobile bar | TODO |

## Definition of done

- [x] Play / Daily / Garage / Level chips work reliably on desktop + Android touch
- [x] `export_presets.cfg` builds a signed release `.aab`
- [ ] Store listing folder has icon + feature graphic + at least 2 phone screenshots
- [ ] Privacy policy markdown published in-repo; data safety form filled as stub
- [ ] `scripts/` includes install/smoke test for connected device
- [ ] Music bed + designed SFX (not only generator beeps)
- [ ] Visual pass reviewed against commercial hypercasual reference

Update this table as each item is verified.
