# Role Reference

Quick lookup for implemented Role baselines.

Role values are the foundation that Species values modify. All current roles have `MaxInv 6` and caps of `Move 10`, `Life 60`, `Comp 130`, and `30` for Pwr/Mag/Eleg/Cele/Def/Cha.

`Lady`, `Maid`, and `Sorceress` are unique-character container roles. Their role values are not reliable balance reads by themselves; use `unique_character_reference.md` for Remilia, Sakuya, and Patchouli's complete current stat picture.

## Role Scope

| Role | Scope | Notes |
| --- | --- | --- |
| `Lady` | Unique player role | Container for Remilia. |
| `Maid` | Unique player role | Container for Sakuya. |
| `Sorceress` | Unique player role | Container for Patchouli. |
| `Guard` | Generic role | Has Meiling as a unique player counterpart. |
| `Miko` | Generic role | Has Reimu as a unique player counterpart. |
| `Troublemaker` | Generic role | Baseline brute role. |
| `Cointaker` | Generic role | Utility blade/knife role. |
| `Witch` | Generic role | Baseline book caster role. |
| `Outrider` | Generic role | Mounted polearm role. |
| `Blade` | Specialist role | Kuchisake-onna defensive bait role. |
| `Archer` | Generic role | Baseline bow role. |

## Base Stats

| Role | Move Type | Move | Life | Comp | Pwr | Mag | Eleg | Cele | Def | Cha |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `Lady` | `FOOT` | 5 | 20 | 100 | 5 | 4 | 7 | 10 | 1 | 8 |
| `Maid` | `RANGER` | 5 | 20 | 100 | 6 | 3 | 11 | 7 | 2 | 7 |
| `Sorceress` | `FOOT` | 4 | 20 | 100 | 0 | 8 | 10 | 4 | 0 | 6 |
| `Guard` | `FOOT` | 4 | 27 | 110 | 6 | 0 | 7 | 3 | 8 | 4 |
| `Miko` | `FOOT` | 4 | 21 | 105 | 6 | 5 | 8 | 8 | 5 | 8 |
| `Troublemaker` | `FOOT` | 4 | 25 | 100 | 8 | 0 | 6 | 6 | 2 | 1 |
| `Cointaker` | `RANGER` | 5 | 18 | 100 | 4 | 0 | 7 | 9 | 1 | 7 |
| `Witch` | `FOOT` | 4 | 18 | 95 | 1 | 9 | 9 | 4 | 1 | 6 |
| `Outrider` | `MOUNT` | 6 | 23 | 95 | 5 | 0 | 8 | 8 | 2 | 3 |
| `Blade` | `RANGER` | 5 | 17 | 100 | 4 | 0 | 4 | 6 | 0 | 0 |
| `Archer` | `FOOT` | 4 | 21 | 100 | 5 | 0 | 9 | 7 | 2 | 5 |

## Growths

| Role | Move | Life | Comp | Pwr | Mag | Eleg | Cele | Def | Cha |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `Lady` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| `Maid` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| `Sorceress` | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| `Guard` | 0.00 | 0.30 | 0.30 | 0.20 | 0.00 | 0.15 | 0.05 | 0.15 | 0.15 |
| `Miko` | 0.00 | 0.25 | 0.35 | 0.20 | 0.20 | 0.25 | 0.20 | 0.10 | 0.25 |
| `Troublemaker` | 0.00 | 0.35 | 0.25 | 0.40 | 0.00 | 0.20 | 0.25 | 0.05 | 0.05 |
| `Cointaker` | 0.00 | 0.20 | 0.30 | 0.15 | 0.00 | 0.25 | 0.35 | 0.05 | 0.30 |
| `Witch` | 0.00 | 0.20 | 0.30 | 0.00 | 0.40 | 0.30 | 0.10 | 0.05 | 0.20 |
| `Outrider` | 0.00 | 0.25 | 0.25 | 0.20 | 0.00 | 0.30 | 0.30 | 0.05 | 0.10 |
| `Blade` | 0.00 | 0.40 | 0.30 | 0.20 | -0.10 | 0.30 | 0.60 | 0.20 | 0.10 |
| `Archer` | 0.00 | 0.25 | 0.25 | 0.25 | 0.00 | 0.35 | 0.25 | 0.05 | 0.20 |

## Access And Features

| Role | Weapon Access | Skills | Passives |
| --- | --- | --- | --- |
| `Lady` | Stick | None | None |
| `Maid` | Blade, Knife | None | None |
| `Sorceress` | Book | None | None |
| `Guard` | Stick, Barrier | `shove_enemy01` | None |
| `Miko` | Gohei, Ofuda | None | None |
| `Troublemaker` | Blunt | None | None |
| `Cointaker` | Blade, Knife | `sabo_cele05` | None |
| `Witch` | Book | None | None |
| `Outrider` | Stick | None | None |
| `Blade` | Blade, Knife | None | `ambush` |
| `Archer` | Bow | None | None |

## Feature Paths

| Feature | Path |
| --- | --- |
| `shove_enemy01` | `res://unit_resources/features/skills/shove_enemy01.tres` |
| `sabo_cele05` | `res://unit_resources/features/skills/sabo_cele05.tres` |
| `ambush` | `res://unit_resources/features/passives/ambush.tres` |

## Notes

- `Lady`, `Maid`, and `Sorceress` are intentionally lightweight role containers. Their final character identities live in the unit scenes through character modifiers, personal skills, and personal passives.
- Unique role growths may eventually receive small "intent hint" values, but specific tuning should stay on the character whenever possible.
- `Blade` is currently a specialist enemy role rather than a broad baseline role.
- `Guard`, `Miko`, `Troublemaker`, `Cointaker`, `Witch`, `Outrider`, and `Archer` are the clearest generic-role baselines at the moment.
