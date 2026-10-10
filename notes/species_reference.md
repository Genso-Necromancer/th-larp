# Species Reference

Quick lookup for implemented species modifiers.

Species values are added on top of Role values. Stat and growth entries only list non-zero modifiers. All current species cap modifiers are `0`.

## Overview

| Species | Move Type | Stat Mods | Growth Mods | Species Features |
| --- | --- | --- | --- | --- |
| `Fairy` | `FLY` | Mag +1, Eleg -1, Cele +2, Cha +2 | Mag +0.10, Cele +0.10, Cha +0.10 | None |
| `Youkai` | `FOOT` | Life +1, Mag -1, Cha -1 | Life +0.05, Pwr +0.05, Mag +0.05, Def +0.05, Cha -0.05 | None |
| `Human` | `FOOT` | Eleg +2, Cha +2 | Eleg +0.05, Cha +0.05 | None |
| `Vampire` | `FLY` | Pwr +1, Mag +1, Cele +1, Cha +2 | Pwr +0.05, Mag +0.10, Cele +0.10 | `canto_night`, `life_steal_rem` |
| `Magician` | `FOOT` | Mag +4 | None | None |
| `Dragon` | `FOOT` | Life +4, Mag +1, Def +2 | Life +0.10, Cele -0.05, Def +0.05 | None |
| `Oni` | `FOOT` | Life +4, Comp -10, Pwr +1, Mag -3, Eleg -2 | Life +0.10, Pwr +0.10, Eleg -0.10, Def +0.10 | None |
| `Sazae-Oni` | `SWIM` | Life +2, Pwr -1, Mag -1, Cele +1, Def +1 | Life +0.05, Cele +0.05 | None |

## Time Notes

Only species with non-zero day/night changes are listed here.

| Species | Day | Night |
| --- | --- | --- |
| `Human` | None | Eleg -1, Cele -1 |
| `Youkai` | None | Pwr +2, Mag +4, Cele +1, Def +1 |
| `Oni` | None | Pwr +2, Mag +6, Cele +1, Def +1 |
| `Sazae-Oni` | None | Pwr +1, Mag +2, Eleg +1, Cele +1, Def +1 |
| `Vampire` | Move -1, Pwr -2, Mag -2, Def -2, Move Type `FOOT` | None |

## Feature Paths

| Feature | Path |
| --- | --- |
| `canto_night` | `res://unit_resources/features/passives/canto_night.tres` |
| `life_steal_rem` | `res://unit_resources/features/skills/life_steal_rem.tres` |

## Notes

- `Sazae-Oni` currently exists to test aquatic Troublemaker-style units on `map_pack_1`.
- `Sazae-Oni` is tuned as a defensive aquatic predator rather than a paid-for Swim variant: shell-like base Def, improving Cele, and strong water terrain synergy.
- Day/night modifiers are written from each species' natural-feeling neutral state: Human and Youkai-style species use day as neutral, while Vampire uses night as neutral.
- Demon-oriented species currently express innate supernatural force through day/night Mag rather than base Mag or Mag growth. Their actual night Mag endpoints are `Sazae-Oni +1`, `Youkai +2`, and `Oni +3` after their neutral/base Mag values are included.
- `SWIM` behaves like standard land movement in most terrain, but gets favorable costs in `River`, `Water`, and `Sanzu`.
- Vampire movement changes through time mods: flying by default, grounded during day.
