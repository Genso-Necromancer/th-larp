# Unique Character Reference

Quick lookup for unique unit data that cannot be cleanly understood from Role and Species alone.

Final stats and growths use the serialized `total_stats` and `total_growth` values in each unit scene. Breakdown rows show the current Role, Species, and Character modifier pieces so mismatches or old manual data are visible instead of hidden.

Move type priority currently follows enum order: `FOOT < RANGER < FLY < MOUNT < ARMOR < SWIM`. The final move type is whichever side of Role or Species wins that priority check.

## Player Units

| Character | Scene | Level | Role | Species | Role Move | Species Move | Final Move |
| --- | --- | ---: | --- | --- | --- | --- | --- |
| Remilia | `res://scenes/units/player_units/remilia.tscn` | 1 | `Lady` | `Vampire` | `FOOT` | `FLY` | `FLY` |
| Sakuya | `res://scenes/units/player_units/sakuya.tscn` | 5 | `Maid` | `Human` | `RANGER` | `FOOT` | `RANGER` |
| Patchouli | `res://scenes/units/player_units/patchouli.tscn` | 1 | `Sorceress` | `Magician` | `FOOT` | `FOOT` | `FOOT` |
| Meiling | `res://scenes/units/player_units/meiling.tscn` | 3 | `Guard` | `Dragon` | `FOOT` | `FOOT` | `FOOT` |
| Reimu | `res://scenes/units/player_units/reimu.tscn` | 1 | `Miko` | `Human` | `FOOT` | `FOOT` | `FOOT` |

### Player Stat Breakdown

| Character | Source | Move | Life | Comp | Pwr | Mag | Eleg | Cele | Def | Cha |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Remilia | Role `Lady` | 5 | 20 | 100 | 5 | 4 | 7 | 10 | 1 | 8 |
| Remilia | Species `Vampire` | 0 | 0 | 0 | 1 | 1 | 0 | 1 | 0 | 2 |
| Remilia | Character Mods | 0 | 6 | 10 | 1 | 0 | 2 | -2 | 1 | -1 |
| Remilia | Final Combination | 5 | 26 | 110 | 7 | 5 | 9 | 9 | 2 | 9 |
| Sakuya | Role `Maid` | 5 | 20 | 100 | 6 | 3 | 11 | 7 | 2 | 7 |
| Sakuya | Species `Human` | 0 | 0 | 0 | 0 | 0 | 2 | 0 | 0 | 2 |
| Sakuya | Character Mods | 0 | 9 | 10 | 2 | 0 | 0 | 3 | 1 | 0 |
| Sakuya | Final Combination | 5 | 29 | 110 | 8 | 3 | 13 | 10 | 3 | 9 |
| Patchouli | Role `Sorceress` | 4 | 20 | 100 | 0 | 8 | 10 | 4 | 0 | 6 |
| Patchouli | Species `Magician` | 0 | 0 | 0 | 0 | 4 | 0 | 0 | 0 | 0 |
| Patchouli | Character Mods | 0 | 3 | 15 | 2 | -1 | 0 | -1 | 1 | 1 |
| Patchouli | Final Combination | 4 | 23 | 115 | 2 | 11 | 10 | 3 | 1 | 7 |
| Meiling | Role `Guard` | 4 | 27 | 110 | 6 | 0 | 7 | 3 | 8 | 4 |
| Meiling | Species `Dragon` | 0 | 4 | 0 | 0 | 1 | 0 | 0 | 2 | 0 |
| Meiling | Character Mods | 0 | 1 | 5 | 3 | 1 | 1 | 2 | -1 | 1 |
| Meiling | Final Combination | 4 | 32 | 116 | 9 | 2 | 8 | 5 | 9 | 5 |
| Reimu | Role `Miko` | 4 | 21 | 105 | 6 | 5 | 8 | 8 | 5 | 8 |
| Reimu | Species `Human` | 0 | 0 | 0 | 0 | 0 | 2 | 0 | 0 | 2 |
| Reimu | Character Mods | 0 | 4 | 7 | 1 | -1 | 0 | 2 | -1 | -2 |
| Reimu | Final Combination | 4 | 25 | 112 | 7 | 4 | 10 | 10 | 4 | 8 |

### Player Growth Breakdown

| Character | Source | Move | Life | Comp | Pwr | Mag | Eleg | Cele | Def | Cha |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Remilia | Role `Lady` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| Remilia | Species `Vampire` | 0.00 | 0.00 | 0.00 | 0.05 | 0.10 | 0.00 | 0.10 | 0.00 | 0.00 |
| Remilia | Character Mods | 0.00 | 0.30 | 0.35 | 0.25 | 0.10 | 0.25 | 0.15 | 0.05 | 0.25 |
| Remilia | Final Combination | 0.00 | 0.30 | 0.35 | 0.30 | 0.20 | 0.25 | 0.25 | 0.05 | 0.25 |
| Sakuya | Role `Maid` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| Sakuya | Species `Human` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.05 | 0.00 | 0.00 | 0.05 |
| Sakuya | Character Mods | 0.00 | 0.25 | 0.35 | 0.25 | 0.10 | 0.25 | 0.30 | 0.10 | 0.15 |
| Sakuya | Final Combination | 0.00 | 0.25 | 0.35 | 0.25 | 0.10 | 0.30 | 0.30 | 0.10 | 0.20 |
| Patchouli | Role `Sorceress` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| Patchouli | Species `Magician` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| Patchouli | Character Mods | 0.00 | 0.30 | 0.40 | 0.10 | 0.45 | 0.35 | 0.05 | 0.05 | 0.25 |
| Patchouli | Final Combination | 0.00 | 0.30 | 0.40 | 0.10 | 0.45 | 0.35 | 0.05 | 0.05 | 0.25 |
| Meiling | Role `Guard` | 0.00 | 0.30 | 0.30 | 0.20 | 0.00 | 0.15 | 0.05 | 0.15 | 0.15 |
| Meiling | Species `Dragon` | 0.00 | 0.10 | 0.00 | 0.00 | 0.00 | 0.00 | -0.05 | 0.05 | 0.00 |
| Meiling | Character Mods | 0.00 | 0.05 | 0.05 | 0.10 | 0.10 | 0.05 | 0.10 | 0.00 | 0.00 |
| Meiling | Final Combination | 0.00 | 0.45 | 0.35 | 0.30 | 0.10 | 0.20 | 0.10 | 0.20 | 0.15 |
| Reimu | Role `Miko` | 0.00 | 0.25 | 0.35 | 0.20 | 0.20 | 0.25 | 0.20 | 0.10 | 0.25 |
| Reimu | Species `Human` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.05 | 0.00 | 0.00 | 0.05 |
| Reimu | Character Mods | 0.00 | 0.00 | 0.05 | 0.05 | -0.05 | -0.05 | 0.10 | -0.05 | -0.10 |
| Reimu | Final Combination | 0.00 | 0.25 | 0.40 | 0.25 | 0.15 | 0.25 | 0.30 | 0.05 | 0.20 |

### Player Features

| Character | Role Skills | Species Skills | Character Skills | Role Passives | Species Passives | Character Passives | Scene-Loaded Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Remilia | None | `life_steal_rem` | None | None | `canto_night` | `fated`, `rem_aura` | `life_steal_rem` and `canto_night` are currently present through Vampire. |
| Sakuya | None | None | `slow_time`, `locked_corpse` | None | None | `night_person`, `lockpick` | None. |
| Patchouli | None | None | None | None | None | None | Current scene-loaded skills come from equipped/debug books: `spell_sunburst`, `spell_debug_life_shear`, `spell_debug_life_mend`, `spell_moonveil`, `spell_debug_eleg_break`, `spell_water_veil`, `spell_silent_rain`, `spell_stonebind`, `spell_sprout`, `spell_iron_thorn`, `spell_selene_ward`, `spell_uproot`, `spell_clear_voice`. |
| Meiling | `shove_enemy01` | None | `toss_enemy`, `daze_test_skill` | None | None | `martial` | `shove_enemy01` is role-granted; `martial_fist` is equipped as her Natural weapon. |
| Reimu | None | None | `slay_fairy` | None | None | `plot_armor` | None. |

### Player Notes

- Remilia: Vampire supplies her `FLY` movement by default/night, while daytime Vampire time mods ground her to `FOOT`.
- Patchouli: Missing intended personal features remain spell memorization and magical counter.
- Meiling: Current final Comp is `116`, while Role + Species + Character Mods add to `115`; keep an eye on this when normalizing unique scene data.

## NPC Units

| Character | Scene | Chapter | Level | Role | Species | Role Move | Species Move | Final Move |
| --- | --- | --- | ---: | --- | --- | --- | --- | --- |
| Cirno | `res://scenes/units/unique_units/cirno.tscn` |  | 3 | `Troublemaker` | `Fairy` | `FOOT` | `FLY` | `FLY` |

### NPC Stat Breakdown

| Character | Source | Move | Life | Comp | Pwr | Mag | Eleg | Cele | Def | Cha |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Cirno | Role `Troublemaker` | 4 | 25 | 100 | 8 | 0 | 6 | 6 | 2 | 1 |
| Cirno | Species `Fairy` | 0 | 0 | 0 | 0 | 1 | -1 | 2 | 0 | 2 |
| Cirno | Character Mods | 0 | 0 | 0 | 4 | 0 | 4 | 0 | 0 | 0 |
| Cirno | Final Combination | 4 | 20 | 100 | 10 | 1 | 7 | 4 | 4 | 2 |

### NPC Growth Breakdown

| Character | Source | Move | Life | Comp | Pwr | Mag | Eleg | Cele | Def | Cha |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Cirno | Role `Troublemaker` | 0.00 | 0.35 | 0.25 | 0.40 | 0.00 | 0.20 | 0.25 | 0.05 | 0.05 |
| Cirno | Species `Fairy` | 0.00 | 0.00 | 0.00 | 0.00 | 0.10 | 0.00 | 0.10 | 0.00 | 0.10 |
| Cirno | Character Mods | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| Cirno | Final Combination | 0.00 | 0.50 | 0.30 | 0.45 | 0.10 | 0.20 | 0.10 | 0.20 | 0.10 |

### NPC Features

| Character | Role Skills | Species Skills | Character Skills | Role Passives | Species Passives | Character Passives | Scene-Loaded Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Cirno | None | None | None | None | None | None | Current scene has `club` equipped. |

### NPC Notes

- Cirno is currently an older/manual unique NPC scene. Its serialized final stats and growths do not cleanly derive from the displayed Role + Species + Character modifier pieces.
- The `Chapter` field is intentionally blank until map/chapter placement is formalized.
