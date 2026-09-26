# Magic Balance Notes

These notes cover spell packages, caster identity, and magic-adjacent equipment. They connect to weapon families, especially Book/Scroll, Gohei, and Ofuda, but they should be treated as their own balance space rather than forced into normal weapon-family logic.

## Magic-Adjacent Equipment Triangle

- Book/Scroll = active magical access.
- Gohei = priestess role-shaping sidearm.
- Ofuda = expendable tactical payload.

Book passives should support the spell package. Gohei passives should shape the wielder's combat/support posture. Ofuda effects should be the limited-use tactical payload.

## Ofuda Pillars

Ofuda currently own four major tactical payload categories: Healing, Curing, Relocation, and Status Effects. The first reference set is Heal, Warp, Cure Sleep, and Sleep; detailed Ofuda item values live in `ofuda_balance_notes.md` and `item_catalog.md`.

## Working Paradigm Hooks

These are the current simple identity hooks for each spell element. The goal is to make each Paradigm as easy to expand as Fire: a new spell should inherit the element's hook first, then vary through cost, range, hit, might, duration, and specific rider values.

| Element | Universal Hook | Working Read |
|---|---|---|
| Fire | Momentum | Fire spells attack and self-buff the caster, rewarding chained aggression. |
| Water | Purge / Purity | Hostile Water removes enemy buffs; friendly Water removes allied debuffs. Water may deal damage, but its defining verb is removing stat-altering effects. |
| Wood | Renewal | Wood spells carry small healing. Friendly Wood heals the target; hostile Wood heals the caster. Mobility can appear on specific Wood spells, but it is not the universal hook. |
| Metal | Efficiency / Value | Metal spells are cheaper than expected for their output, but have a lower ceiling than peer damage spells. Conversion and exchange can appear as advanced spice, not the baseline. |
| Earth | Extended Reach / Defensive Projection | Earth spells reach farther than peer spells, letting the caster hold favorable positions and project control. Defense/control riders can exist on specific spells, but reach is the current universal hook. |
| Sun | Force | Sun spells cost more and hit harder, with little or no rider complexity. |
| Moon | Hidden Protection | Moon spells help the caster or target act under cover, currently pointing toward temporary Shade-like safety and proactive protection. |

## Damage Tiering

This is a working damage-tier order, not a rigid rule for every individual spell.

1. Sun
2. Fire
3. Earth
4. Metal
5. Moon
6. Water
7. Wood

## Draft Intro Fire Book Spell Package

- Fire Ball: Cost 4, Mt 5, Hit 80, Range 1-2. On hit, self-buffs Celerity +2 for 2 turns. Careful attack that introduces Fire's stoking concept: repeated casting can maintain a rolling self-buff.

## Draft Elemental Spell References

Draft Proc uses the first-pass hostile proc budget from `effect_proc_budget_notes.md`.

| Element | Spell | Cost | Range | Hit | Mt | Type | Draft Proc | Effect |
|---|---|---:|---:|---:|---:|---|---:|---|
| Fire | Fire Ball | 4 | 1-2 | 80 | 5 | Mag | Always | Self Cele +2 for 2 turns. |
| Water | Purge The Body | 5 | 1-2 | 80 | 4 | Mag | Always | Purge target's curable buffs. |
| Water | Purity of Spirit | 7 | 1-2 ally | 100 | 0 | Ally Only | Always | Purify target's curable debuffs. |
| Wood | Creeping Vine | 5 | 1-2 | 85 | 2 | Mag | Always | Heal self 3 Life on cast. |
| Metal | Iron Shard | 2 | 1-2 | 85 | 4 | Mag | n/a | Efficient low-cost damage spell. |
| Metal | Metal Blade | 2 | 1-2 | 90 | 4 | Phys | n/a | Efficient physical spell for high-Mag targets. |
| Earth | Stonebind | 10 | 1-3 | 70 | 0 | Mag | 70% | On hit: Dazed for 1 round. |
| Earth | Stone Body | 6 | Self | 100 | 0 | Self Only | Always | Self Def +3, Move -2 for 2 rounds. |
| Sun | Celestial Spark | 8 | 1-2 | 75 | 9 | Mag | n/a | Pure heavy damage. |
| Moon | Eclipse | 6 | 1-2 | 85 | 3 | Mag | Always | Grant Shade to caster for 1 round. |
| Moon | Selene's Ward | 10 | 1-2 ally | 100 | 0 | Ally Only | Always | Blocks next incoming status; lasts 2 rounds. |

## Retired / Debug Spell Resources

These resources may remain useful for testing systems or comparing old ideas, but they are not current Paradigm references.

- Ignite: retired Fire spell.
- Ember: retired Fire spell.
- Flare: retired Fire spell.
- Purity of Voice: debug/retired Silence spell; Silence is leaning back toward Ofuda.
- Wakeleaf: debug/retired Cure Sleep spell.
- Uproot: debug/retired Cure Dazed spell.
- Clear Voice: debug/retired Cure Silence spell.
- Acceptable Berry: retired Wood HoT spell.
- Iron Thorn: debug/retired DoT spell.
- Solar Spark: retired Sun spell.
- Moonveil: retired Moon Graze spell.

## Proc Notes

- Always for friendly/self effects means the effect should apply if the action is valid. It does not roll against hostile Resist.
- Always for Purge means the effect should apply if the attack/action hits. The target requirement is already narrow, and Purge resets positive enemy state rather than applying a negative state.
- n/a means the spell currently has no separate proc-budgeted effect; normal hit, damage, and combat math are the relevant checks.
- Hostile status or DoT spells should still be tuned per spell if their access, duration, damage, or tactical context is unusual.

## Element Summary

The following is based on the Chinese Paradigms.

Element Mythos Reference:
Fire (火) 	Tuesday (火曜日) 	Change and movement. Fire assists earth and inhibits metal. Fire's ashes pile up to create earth, but it melts metal.
Water (水) 	Wednesday (水曜日) 	Silence and purification. Water assists wood and inhibits fire. Water nourishes wood, but it quenches fire.
Wood (木) 	Thursday (木曜日) 	Life and awakening. Wood assists fire and inhibits earth. Wood feeds fire, but it absorbs away water and nutrients from the earth.
Metal (金) 	Friday (金曜日) 	Wealth and abundance. Metal assists water and inhibits wood. Metal gives forth water (by condensation), but it tears up the roots of trees.
Earth (土) 	Saturday (土曜日) 	Foundation and immobility. Earth assists metal and inhibits water. Earth contains metal, but it absorbs water.
Sun (日) 	Sunday (日曜日) 	Activity and offense.
Moon (月) 	Monday (月曜日) 	Passivity and defense. Stealth, stillness, the hidden.
