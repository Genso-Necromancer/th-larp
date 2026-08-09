# Missing Feature Notes

## Current Baseline Pass

- Reimu, Meiling, Patchouli, Sakuya, and Remilia have initial testing stat lines.

## Patchouli Follow-Up Features

Patchouli is intentionally missing two character features during the initial baseline-stat pass:

- Spell Memorization: setup-phase spell slotting from spellbooks in inventory, allowing Patchouli to keep access to selected spells while freeing the books for other mages.
- Magical Counter: personal passive that lets Patchouli perform a magical reaction attack when eligible to counter, protecting her spellbook durability and reinforcing her pure-mage identity.

## Remilia Follow-Up Features

Remilia is intentionally missing a character feature during the initial baseline-stat pass:

- Superior Vampire: personal passive that makes Remilia count as a higher level than she really is for unlocking vampire species skills/passives, giving her a character-appropriate sense of superiority and helping her retain an edge over other vampires.

## Weapon Follow-Up Features

- AI needs to understand cycle charging: repositioning specifically to build future charge-polearm damage instead of only valuing immediate attacks.
- Enemy-turn start/end lag: there is a noticeable pause after player turn completion and at enemy-turn startup. This is suspected to be AI evaluation inefficiency and is intentionally deferred until the AI optimization pass.

## Magic Follow-Up Features

- Shove/Toss/Pull invalid-space resolution: direct relocation effects need a formal per-subtype resolution pass when their inferred destination is blocked or invalid. Shove/Toss currently stop through the old shove resolver, but this still needs intentional rules and validation.
- Rescue invalid-space resolution: Rescue-style relocation currently chooses a valid adjacent caster-side space for the debug Ofuda, but still needs a formal blocked-destination design pass because it relocates a distant target beside the caster rather than projecting a target away from the caster.
- Temporary movement-type changes: Wood-style temporary Ranger/other move-type swaps need explicit effect support. Movement type is stored and used by pathing, but current buff/debuff stat aggregation does not modify `move_type`.
- Hostile spell/effect proc rates: hostile effects currently use default effect-hit/resist behavior unless explicitly set. Good proc offsets for Purge, Silence, Daze, Bleed/DoT, and similar effects need a dedicated tuning pass.
- Freeze status family: water/ice effects may use a stacking freeze mechanic. First stack applies a combined debuff; second stack replaces it with a frozen state that forces 0 Move and 0 Graze for its duration.
- DoT identity split: current generic DOT needs design separation into possible keyword families such as Bleed, Burn, and Poison. Each may need distinct cure/support hooks.
- DoT cure support: add a cure path for damage-over-time conditions once DoT families are finalized.
- Metal paradigm pass: Metal spell mechanics function, but the current representation does not fully express the intended Metal paradigm.
- Water/Ice paradigm pass: Water can include ice-themed spells, especially once Freeze exists.
- Purge/Purity limits: `PURGE` and `PURITY` currently remove all matching curable effects. Water spell design needs support for removing only a limited number of buffs/debuffs.
- Shade behavior: Moon's Shade passive exists as reference data, but AI target valuation does not yet understand Shade.
- Temporary passive grants: `ADD_PASSIVE` effects can describe a spell granting a passive, but temporary passive application/removal is not fully live yet.

## Recently Implemented Magic Features

- Silence status effect: prevents magical skills from being used while active.
- Magic skill tagging: skills now have an explicit `magical` flag independent from damage type.
- Percent effect values: `DAMAGE`, `HEAL`, `DOT`, and `HOT` can resolve float values as percent of max Life where supported. `LIFE_STEAL` now correctly supports float values such as `0.5`.
- Periodic damage/healing: DoT/HoT effects can be stored in duration pools and tick as flat or percent Life values.
- Purge/Cure boundary: Purge removes curable active buffs; Cure removes curable debuffs and/or statuses.


## Species

- Potential for Yamanba Species/Role which Mix Physical and some Magic. They're mountain hags and witches. In Touhou the character Nemuno Sakata is a butcher knife wielding Yamanba giving inspiration to this.
