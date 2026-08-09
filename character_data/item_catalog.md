# Item Catalog

Working list of implemented item resources, sorted by family. Template/base resources are omitted unless they function as real items.

## Weapons

### Blade

| Item | Resource ID | Mt | Hit | Wt | Range | Barrier | Dur | Notes |
|---|---|---:|---:|---:|---|---|---:|---|
| Basic Blade | `blade_basic` | 7 | 65 | 4 | 1 | 2 / 30% | 40 | Baseline reliable defensive blade. |
| Scissor Blade | `scissor_blade_basic` | 5 | 80 | 0 | 1 | 2 / 10% | 30 | Older/high-accuracy blade test item. |

### Blunt

| Item | Resource ID | Mt | Hit | Wt | Range | Barrier | Dur | Notes |
|---|---|---:|---:|---:|---|---|---:|---|
| Basic Blunt | `blunt_basic` | 10 | 55 | 7 | 1 | 0 / 0% | 40 | Baseline defense-breaking blunt weapon. |
| Club | `club` | 6 | 65 | 0 | 1 | 4 / 1% | 40 | Older blunt test item. |

### Polearm

| Item | Resource ID | Mt | Hit | Wt | Range | Barrier | Dur | Notes |
|---|---|---:|---:|---:|---|---|---:|---|
| Charging Polearm | `polearm_charge_basic` | 7 + 1H | 60 | 5 | 1 | 0 / 0% | 40 | Baseline Charge polearm. |
| Bracing Polearm | `polearm_brace_basic` | 9 | 60 | 6 | 1 | 0 / 0% | 40 | Grants `Brace`, negating incoming Charge bonus. |
| Reach Polearm | `polearm_reach_basic` | 8 | 60 | 9 | 2 | 0 / 0% | 40 | Baseline exact-2-range polearm. |
| Gungnir | `gungnir` | 17 | 90 | 0 | 1 | 3 / 10% | 25 | Late-game/test Remilia weapon. |

### Bow

| Item | Resource ID | Mt | Hit | Wt | Range | Close | Far | Dur | Notes |
|---|---|---:|---:|---:|---|---|---|---:|---|
| Hunter Bow | `hunter_bow_basic` | 9 | 60 | 5 | 2 | 1 | 3 | 35 | Damage-pressure baseline bow. |
| Harrier Bow | `harrier_bow_basic` | 6 | 65 | 5 | 2-3 | - | 4 | 35 | Effect-pressure bow for quiver play. |

### Knife

| Item | Resource ID | Mt | Hit | Wt | Range | Barrier | Dur | Notes |
|---|---|---:|---:|---:|---|---|---:|---|
| Dagger | `knife_dagger` | 5 | 75 | 2 | 1-2 | 0 / 0% | 25 | Baseline 1-2 range knife for aggressive presence and retaliation. |
| Silver Knife | `knife_silver` | 4 + 2 true | 70 | 2 | 1 | 0 / 0% | 30 | Baseline puncture knife; low might with on-hit true damage for subverting defenses. |

### Book / Scroll

| Item | Resource ID | Mt | Hit | Wt | Range | Barrier | Dur | Notes |
|---|---|---:|---:|---:|---|---|---:|---|
| Fire Book | `book_fire` | 1 | 60 | 6 | 1 | 0 / 0% | 10 | Grants Fire Ball. |
| Debug Effect Book | `book_debug_effects` | 1 | 100 | 0 | 1 | 0 / 0% | 99 | Debug-only test book for damage, percent damage/heal, buff, debuff, Purge, Daze, Silence, DOT, HOT, status buffer, Cure Daze, and Cure Silence. |

### Gohei

| Item | Resource ID | Mt | Hit | Wt | Range | Barrier | Dur | Notes |
|---|---|---:|---:|---:|---|---|---:|---|
| Simple Gohei | `gohei_simple` | 6 | 65 | 4 | 1 | 0 / 0% | 40 | Basic priestess sidearm; passive-free reference body. |
| Evasion Ward Gohei | `gohei_evasion_ward` | 3 | 55 | 4 | 1 | 0 / 0% | 40 | Minmax support sidearm; grants +10 Graze while any enemy is adjacent. |
| Status Charm Gohei | `gohei_status_charm` | 5 | 60 | 4 | 1 | 0 / 0% | 40 | Moderate stat penalty for +2 Cha while equipped. |
| Fairy Hunter Gohei | `gohei_hunter_fairy` | 6 | 65 | 4 | 1 | 0 / 0% | 40 | Standard body with +10 Hit when targeting Fairy species. |

### Natural

| Item | Resource ID | Mt | Hit | Wt | Range | Barrier | Dur | Notes |
|---|---|---:|---:|---:|---|---|---:|---|
| Martial Fist | `martial_fist` | 0 | 0 | 0 | 1 | 0 / 0% | 1 | Meiling-style natural weapon shell. |
| Unarmed | `unarmed` | 0 | 0 | 0 | 0 | 0 / 0% | 1 | Fallback unarmed resource. |

## Ofuda

| Item | Resource ID | Mt | Hit | Range | Dur | Notes |
|---|---|---:|---:|---|---:|---|
| Defense Prayer | `defense_prayer` | 0 | 0 | 1 | 10 | Defensive buff Ofuda. |
| Healing Ofuda | `ofuda_heal0` | 0 | 0 | 1 | 20 | Basic healing Ofuda. |
| Heal Ofuda | `ofuda_heal_basic` | 0 | 100 | 1 | 20 | Reference healing Ofuda; heals target ally for 10 Life. |
| Warp Ofuda | `ofuda_warp_basic` | 0 | 100 | 1 | 5 | Reference relocation Ofuda; uses two-step ally target plus destination placement. |
| Rescue Ofuda | `ofuda_rescue_debug` | 0 | 100 | 2-5 | 5 | Debug relocation Ofuda; pulls a distant ally to a valid empty space beside the caster. |
| Cure Sleep Ofuda | `ofuda_cure_sleep` | 0 | 100 | 1-2 | 10 | Reference cure Ofuda; cures Sleep from target ally. |
| Sleep Ofuda | `ofuda_sleep_basic` | 0 | 75 | 1-2 | 5 | Reference hostile status Ofuda; applies Sleep for 2 rounds at 50% base proc after hit. |

## Accessories

### Barrier Items

| Item | Resource ID | Wt | Effects | Notes |
|---|---|---:|---|---|
| Small Barrier | `barrier_small` | 2 | Barrier +4, Barrier Chance +40 | Light defensive barrier item. |
| Medium Barrier | `barrier_medium` | 7 | Barrier +9, Barrier Chance +40 | Heavy defensive barrier item. |

### Quivers

| Item | Resource ID | Wt | Effects | Notes |
|---|---|---:|---|---|
| Basic Quiver | `quiver_basic` | 0 | Bow durability cost +1 | Structural quiver baseline. |
| Barbed Quiver | `quiver_barbed` | 0 | Bow durability cost +1; on-hit Cele -3, 80 proc, 1 turn | First effect-pressure quiver. |

### General Accessories

| Item | Resource ID | Wt | Effects | Notes |
|---|---|---:|---|---|
| Power Ring | `pwr_ring01` | 0 | Power buff | General accessory test item. |

## Consumables

| Item | Resource ID | Range | Dur | Notes |
|---|---|---|---:|---|
| Pizza | `pizza` | 0 | 8 | Basic consumable healing item. |
| Power Item | unset | 0 | 1 | Test consumable with no resource ID set. |
