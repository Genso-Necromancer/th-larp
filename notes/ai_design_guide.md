# AI Design Guide

## Purpose

This is the stable design reference for developing and reviewing the game's AI. It records the intended experience and the principles implementation decisions should serve. It is not a claim that these capabilities currently exist, nor a substitute for a task backlog.

When implementation becomes complicated or priorities become unclear, return to this document before adding another exception or scoring bonus. Change these principles deliberately when the design changes, not merely to describe whatever the current code happens to do.

## Core Goal

Create competent, fair opposition that understands the battle it is participating in and uses its units together. The goal is not maximum playing strength or a tactically oppressive opponent. It is an opponent that can use the game's mechanics meaningfully without depending on passive behavior, predictable exploits, or unfair advantages to present a challenge.

The player should succeed through understanding threats, controlling space, managing resources, and making good decisions. The AI should respect those decisions, not invalidate them through hidden knowledge.

## Desired Behavior

### Pursue The Battle's Objective

The AI should evaluate actions in the context of what its side needs to achieve or prevent. A favorable tile is useful because of what occupying it enables, protects, or denies, not simply because it has strong terrain bonuses.

For example, a swimmer may use water to flank, survive an approach, or threaten a useful route. Sitting safely in water while leaving the seize objective exposed is not automatically a good position.

Defensive play and waiting remain valid. Avoiding passivity does not mean every unit must advance or attack. Holding a position must have a purpose, such as protecting an approach, maintaining support, or presenting a credible threat.

### Coordinate Units And Actions

The AI should recognize the practical value of healing, buffs, debuffs, cures, relocation, and other utility when those actions improve the situation or enable subsequent actions.

It should distinguish a useful coordinated attack from several units committing to a target without regard for the resulting losses or exposure. Concentrating attacks is valid; suicidal dogpiling should not be the default substitute for coordination.

Support is not inherently desirable just because a support action is available. Its value depends on the actual effect, recipient, timing, and likely opportunities to benefit from it.

### Choose Activation Order By Opportunity

Unit importance and the value of activating that unit now are different things.

A valuable unit may deserve protection or preservation of its options. That does not mean it should activate first. In particular, an important unit or boss with nothing useful to do should generally wait after units that have meaningful actions, unless waiting now has a specific tactical benefit.

Activation order must account for expiring opportunities, support dependencies, threats, and the actual faction schedule. A unit's role or assigned job must not automatically make its wait action outrank another unit's useful action.

## Fairness And Uncertainty

- Never inspect, predict from the RNG state, or consume the live RNG sequence to discover whether a future action will succeed.
- Evaluate risk using legitimate information: hit and effect chances, possible outcomes, known mechanics, and the current observable battle state.
- Risky actions are allowed. A low-hit attack can be justified by its possible reward or lack of better alternatives; it must not be chosen because the AI knows it will hit or crit.
- Do not treat a forecast's all-hit damage projection as a guaranteed outcome.
- Use a consistent treatment of uncertainty when comparing outgoing damage, retaliation, effects, and kills.
- Predict reasonable player responses without knowing the player's actual future choice.

The precise probability model and risk preferences remain implementation and tuning decisions. Their purpose is coherent judgment, not certainty or omniscience.

## Planning Horizon

The intended short search is over three activations:

1. A candidate action by the currently acting AI faction.
2. A plausible response by whichever faction actually acts next.
3. A possible follow-up by whichever faction acts after that.

An activation is a unit's opportunity to act, not an entire faction's remaining turns or a complete round. Do not assume the sequence always alternates enemy, player, enemy. Consecutive allied activations should allow the AI to recognize immediate combinations.

This horizon should help compare outcomes such as attacking now versus applying a debuff that makes a later attack more useful. It is a bounded planning tool, not a promise of exhaustive optimal play.

Search must use faithful resulting states, including relevant movement, damage, effects, deaths, resource use, and action availability. Round boundaries and their effects matter when the horizon crosses them. Searching further through inaccurate states is not an improvement.

### Pruning And Search Budget

Order promising candidates early and stop exploring branches when valid bounds establish that they cannot improve the current choice. An opposing response can establish that a candidate is worse than an alternative already found.

Chance outcomes require additional care: a single possible miss or other unfavorable random result does not by itself establish that the whole action is worse. Probability-aware branches need appropriate bounds or an explicitly documented approximation.

Keep search bounded and responsive. Exact candidate limits, response breadth, probability approximations, and time budgets are not yet fixed. They should be measurable and adjustable without rewriting the strategic intent.

## Responsibilities Of The Decision System

| Responsibility | What it should answer |
|---|---|
| Legal action generation | What can this unit actually do, from which spaces, with which equipment or skill? |
| Objective context | What must this side accomplish or prevent, and which positions or threats matter to that? |
| Roles and jobs | What opportunities should this unit tend to consider, given its purpose and the current situation? |
| Simulation | What changes if this action occurs? |
| Evaluation | How desirable is the resulting situation, including costs and risk? |
| Search | How might the next activations change that judgment? |
| Execution | Carry out the chosen legal action through the normal gameplay systems. |

Weighted scoring remains useful for comparing targets, actions, equipment, positions, and resulting board states. The problem is not the existence of weights; it is using bonuses in place of understanding consequences or allowing unrelated priorities to override action quality.

These responsibilities should cooperate without each developing a different interpretation of movement, combat, targeting, or turn order. Reuse authoritative rules where practical. Explicit map restrictions remain legitimate authoring tools, but basic competence should not depend on scripting a specific tactic for every encounter.

## Limits And Non-Goals

- Do not pursue chess-engine strength as an end in itself.
- Do not make every unit behave identically in pursuit of a single numerical optimum.
- Do not remove all exploitable weaknesses. Deliberate unit weaknesses, baiting, and counterplay are part of the game; accidental systemic blind spots are the problem.
- Do not solve every observed quirk by adding a special-case bonus.
- Do not require exhaustive simulation of every future branch before the AI can be useful.
- Do not tune difficulty through access to hidden RNG results or different mechanical rules.

## Decision Checklist

Before accepting an AI change, ask:

1. Does it serve the map objective and intended tactical experience, rather than merely improve a local score?
2. Does it distinguish a unit's importance from the usefulness of acting with it now?
3. Does it reflect an actual consequence, including the opportunity cost and likely response?
4. Does it preserve fair uncertainty and meaningful player counterplay?
5. Does it use the same legality and mechanics as live gameplay?
6. Does it generalize to other units and maps without requiring a collection of exceptions?
7. Can we explain and test why the AI chose differently?
8. Is the added complexity and runtime cost justified by a meaningful behavioral improvement?

## Behavioral Checks

These are evaluation scenarios, not rigid scripts requiring one predetermined move in every board state.

| Scenario | Evidence of progress |
|---|---|
| Water beside an exposed seize approach | Swimmers weigh flanking and interception against camping, rather than taking terrain value in isolation. |
| Boss can only wait; allies have useful actions | Boss importance alone does not force an early wait. |
| Attack versus debuff | The AI can recognize when a debuff enables a better response or follow-up, and when immediate damage is preferable. |
| Friendly support choices | Healing, buffs, and cures are evaluated by what they actually change, not all treated as healing. |
| Consecutive faction activations | Planning follows the real schedule and can recognize back-to-back cooperation. |
| Risky hit or crit opportunity | Choice is justified by probabilities and stakes, not the actual future roll. |
| Strong terrain with a ranged counter | The AI considers the threat and positional consequences instead of treating terrain as unconditional safety. |
| Directional wall or equipment restriction | Simulated candidates remain legal when executed by the game. |

Decision diagnostics should make the selected action, meaningful alternatives, objective context, and main reasons understandable. Otherwise apparent improvements are difficult to distinguish from coincidence.

## Implementation Direction

The agreed dependency order is:

1. Align candidate legality with live movement, targeting, and equipment rules.
2. Make simulated actions produce faithful resulting states and activation progression.
3. Establish a shared board evaluator for objectives, survival, positioning, and resources.
4. Add bounded action-response-follow-up search with fair uncertainty handling.
5. Refine roles and jobs as guidance without letting job rank automatically outweigh action usefulness.

This order is a starting plan, not a restriction against fixing a prerequisite when discovered. Verify each stage before relying on it in the next.

### Starting Point: Source Audit, 2026-11-10

The live AI currently ranks immediate actions, with hard job priority ahead of action score. The old search scaffold is not the live decision path. Simulation does not yet apply the full consequences of combat and support, and parts of candidate generation have drifted from live rules. These are implementation gaps, not intended design.

For unit authoring, `AI Role` is currently active; `Archetype` is an unused legacy field. Review existing authored values before removing it. `AI Task` provides separate assignments, with uneven implementation coverage. These technical details may change without changing the goals above.

## Related Notes

- [Project roadmap](project_roadmap.md): whole-game milestones.
- [Feature backlog](feature_backlog.md): focused feature work.
- [Missing feature notes](missing_feature_notes.md): outstanding mechanics and integration gaps.
