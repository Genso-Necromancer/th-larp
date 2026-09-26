# Ofuda Balance Notes

Ofuda are expendable tactical payloads for priestess-style roles. They should be the cleanest and most reliable home for four major mechanics:

- Healing
- Curing
- Relocation
- Status effects

Unlike Books, Ofuda should not feel like a broad spell kit with repeatable damage. Unlike Gohei, they are not a sidearm that shapes the wielder's combat posture. Their identity is limited-use intervention: spend a charge to solve a concrete tactical problem.

## Reference Ofuda

| Ofuda | Resource ID | Cost | Range | Hit | Durability | Effect |
|---|---|---:|---|---:|---:|---|
| Heal Ofuda | `ofuda_heal_basic` | 4 | 1 | 100 | 20 | Heal target ally for 10 Life. |
| Warp Ofuda | `ofuda_warp_basic` | 8 | 1 | 100 | 5 | Friendly relocation payload; select an ally, then select the destination. |
| Rescue Ofuda | `ofuda_rescue_debug` | 8 | 2-5 | 100 | 5 | Debug relocation payload; pulls a distant ally to a valid empty space beside the caster. |
| Cure Sleep Ofuda | `ofuda_cure_sleep` | 3 | 1-2 | 100 | 10 | Cure Sleep from target ally. |
| Sleep Ofuda | `ofuda_sleep_basic` | 8 | 1-2 | 75 | 5 | On hit, 50% base proc to apply Sleep for 2 rounds. |

## Current Reference Rules

- Friendly Healing, Curing, and Relocation Ofuda should not roll hostile proc/resist. If the action is valid, the payload should work.
- Hostile Status Ofuda should still use normal hit first, then effect proc/resist. Sleep starts at the stricter 50% status baseline.
- Ofuda can overlap with Book magic in isolated cases, but Ofuda should remain the best and most plentiful source of clean curative and relocation effects.
