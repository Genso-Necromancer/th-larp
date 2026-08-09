# Effect Proc Budget Notes

These values are first-pass guidance for hostile effect proc rates. They are not final balance locks.

Current natural formulas:

- EffHit = Cha + Eleg / 2
- Resist = Cha * 2
- Final Proc = Effect Proc + User EffHit - Target Resist

## First-Pass Hostile Proc Budget

| Effect Category | Draft Proc | Notes |
|---|---:|---|
| Debuff: Stat | 75% | Neutral baseline. Tune per stat, potency, duration, access, timing, and late-game scaling. |
| Status: Daze | 70% | Strong tempo control, but less absolute than Sleep. Meiling-style personal Toss + Daze can remain always-proc because the whole skill package depends on it. |
| Status: Sleep | 50% | Premium hard control. Should require high EffHit, setup, or specialized access to become reliable. |
| Status: Silence | 60% | Narrower than Sleep but highly punishing against spellcasters. Dedicated control/caster units should threaten it; random low-EffHit units should not do so casually. |
| DoT | 80% | Attrition pressure. High draft proc is a reminder that DoTs must be modest when split into archetypes because they can ignore defenses and tick over time. |
| Purge | Always | Target requirement is already niche, and Purge resets a buffed enemy rather than pushing them into a negative state. If the action hits, it should work. |
| Relocation: Primary Physical Utility | Always | Shove/Pull/Toss as the action's purpose should work if the action connects, since the opportunity cost is the action itself. |
| Relocation: Friendly Utility | Always | Warp/Rescue-style ally movement should not roll hostile proc/resist. |
| Relocation: Secondary Rider | 65% | Default when shove/pull is attached to an action that already has another purpose. |

## Severity Ladder

- Always: board-reset or core-position actions.
- 80%: attrition pressure.
- 75%: general stat pressure.
- 70%: moderate-hard tempo control.
- 65%: secondary positional rider.
- 60%: narrow but punishing caster control.
- 50%: hard disable.

## Excluded From This Phase

| Effect Category | Reason |
|---|---|
| Add Skill / Add Passive | Equipment/system behavior, not a hostile proc budget. |
| Time Manipulation | Sakuya/time-system interaction; bespoke and usually always-proc. |
| Damage Effect | Too context-specific. True, percent, and rider damage need individual handling. |
| Composure Damage Effect | Too context-specific. Needs skill context before budgeting. |
| Acted | Internal state/status-like code hook, not a normal applied status. Daze is the healthier external design for this kind of play. |

## DoT Caution

DoTs can be powerful because they may ignore Def/Mag and keep applying pressure after the initial action. They also have natural drawbacks: delayed payoff, possible cure interaction, and the fact that immediate damage can remove a target from play before attrition matters. Keep the 80% draft value as a design reminder, but tune individual DoT families around duration, stacking, cure access, and whether their damage is flat or percent-based.
