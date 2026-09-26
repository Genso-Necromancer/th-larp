# Development Roadmap

This roadmap is a working production guide, not a promise that every listed feature is final. Its purpose is to reduce decision fog by sorting work by dependency, testing value, and risk of rework.

## Roadmap Rule

When unsure what to work on next, prefer the task that makes more of the current game testable.

Avoid adding large new content or late-game systems until the baseline combat sandbox can answer simple questions:

- Do reference units and weapons express their intended identities?
- Are forecasts, tooltips, and targeting clear enough to trust?
- Are Life, Hit, Graze, Barrier, Weight, Composure, terrain, and status rates in a usable first-pass range?
- Does the player have enough information to make intentional tactical choices?

## Phase 0: Current Foundation

Status: mostly complete for baseline purposes.

Completed or usable enough:

- Initial player unit stat lines: Reimu, Meiling, Patchouli, Sakuya, Remilia.
- Generic reference roles: Guard, Miko, Troublemaker, Witch, Outrider, Cointaker, Archer.
- Human and Youkai reference species.
- Lv30 cap.
- Weapon weight and Cele penalty.
- Weapon family reference items for Blade, Blunt, Polearm, Bow, Knife, Book/Scroll, Gohei, Natural, Barrier Items.
- Quiver accessory support.
- Barrier accessory category support.
- Bow range bands.
- Polearm Charge and Brace.
- Warp and Rescue reference Ofuda.
- Magic skill tagging, Silence, Purge/Purity, DoT/HoT, percent effect values.
- Item/equipment notes and baseline comparison sheets.

Phase 0 is not perfect, but it is enough to support a controlled test loop.

## Phase 1: Balance Sandbox

Goal: formalize a repeatable environment for checking the current combat ecosystem.

Priority: Now.

Current map:

- `feature_workshop.tscn` works as the broader systems sandbox. Balance testing now belongs in `combat_sandbox.tscn`, a duplicate/sibling map reserved for controlled encounter pockets.

Deliverables:

- Controlled `combat_sandbox.tscn` map with small encounter pockets.
- Deployed player test roster using current baseline units.
- Generic enemies representing each baseline role/species pair.
- Item placements or inventories covering every reference weapon family.
- Test access to Barrier Items, Quivers, Ofuda, Gohei, Books, and basic melee weapons.
- A simple written checklist of expected tests per encounter pocket.

Suggested encounter pockets:

- Basic melee: Blade, Blunt, Charge Polearm, Brace Polearm, Reach Polearm.
- Defensive equipment: Guard with Small/Medium Barrier against common attackers.
- Mobility pressure: Outrider and Remilia-style Canto/Fly pressure.
- Ranged pressure: Archer with Hunter Bow, Harrier Bow, Basic Quiver, Barbed Quiver.
- Specialist pressure: Cointaker with Blade/Knife.
- Priestess tools: Reimu/Miko with Gohei and Heal/Warp/Rescue/Cure/Sleep Ofuda.
- Mage tools: Patchouli/Witch with reference spell book.
- Day/night: Remilia and species day/night stat shifts.

Exit criteria:

- Every reference weapon family can be equipped and used.
- Forecasts do not lie about major values.
- Tooltips expose the relevant item values.
- Common action flows do not freeze or strand the game state.
- At least one pass of notes exists for what feels overtuned, undertuned, unclear, or broken.

## Phase 2: Forecast And Feedback Trust

Goal: make testing reliable before deeper tuning.

Priority: Now/Soon.

Work items:

- Verify forecast matches combat for Hit, Damage, Crit, Barrier, Charge, Brace, Quiver effects, Hunter effects, range-band penalties, and pure skill actions.
- Verify item tooltips for Might, Charge, Weight, Barrier, range bands, passives, and equipment effects.
- Verify targeting overlays for Range, Close, Far, Warp destination selection, Rescue, Ofuda, and skills.
- Verify status/buff tray feedback for buffs, debuffs, statuses, DoT/HoT, Purge/Purity, and status buffers.
- Confirm focus viewer ignores inactive/undeployed units at the storage corner.
- Keep debug items separated from intended reference items in notes and test maps.

Exit criteria:

- A player can inspect a unit/item, forecast an action, execute it, and see results that match the preview closely enough for balance testing.

## Phase 3: First Balance Pass

Goal: tune the existing baseline values before creating larger content sets.

Priority: Soon.

Primary questions:

- Are early Life breakpoints sturdy enough without creating stat bloat?
- Are Hit/Graze values too low once terrain is included?
- Are Barrier values reducing damage at the desired frequency and severity?
- Does Weight create meaningful Pwr value without crushing low-Pwr roles too harshly?
- Are reference weapon Mt values creating appropriate kill timing?
- Are Composure costs and losses visible enough to matter without smothering action?
- Do hostile proc rates feel fair using EffHit and Resist?
- Are day/night shifts meaningful but not exhausting to plan around?

Suggested order:

1. Life and damage breakpoints.
2. Hit/Graze and terrain.
3. Barrier and Weight.
4. Composure flow.
5. Status/effect proc rates.
6. Day/night tactical impact.

Exit criteria:

- A second version of the baseline comparison sheet exists with notes from actual test-map play.
- Any obvious reference item or role outlier has been adjusted or flagged.

## Phase 4: Core Character Identity Features

Goal: add missing personal mechanics after the baseline can measure them.

Priority: Soon, after Phase 1 and enough of Phase 2.

Player unit features:

- Patchouli: Spell Memorization.
- Patchouli: Magical Counter.
- Remilia: Superior Vampire level-count passive.
- Remilia: day/night aura swap and vampire skill progression review.
- Sakuya: time-manipulation identity review, including Locked Corpse and future time tools.
- Meiling: Toss final behavior and invalid-space rules.
- Reimu: Slayer progression plan and Miko/Gohei/Ofuda role checks.

Why after the sandbox:

- These features define the characters, but they can easily distort baseline readings if added before reference combat is understood.
- Once the sandbox exists, each character feature can be tested against known baseline scenarios.

Exit criteria:

- Each core player unit has a written testing identity and at least one map situation where that identity is visible.

## Phase 5: Relocation And Tactical Utility Hardening

Goal: make movement-control tools reliable enough for real map design.

Priority: Soon/Later depending on how much the test map uses relocation.

Work items:

- Shove invalid-space resolution.
- Pull invalid-space resolution.
- Toss invalid-space resolution.
- Rescue blocked-destination design pass.
- Warp destination validation polish.
- Determine which relocation effects are player-only, AI-safe, or require special AI handling.

Exit criteria:

- Relocation effects have explicit rules for blocked, occupied, out-of-bounds, and impassable destinations.
- Map design can safely use these tools without softlocking or creating unclear outcomes.

## Phase 6: Magic Paradigm Expansion

Goal: turn spell references into a sustainable spell design language.

Priority: Later, after first balance pass.

Work items:

- Metal paradigm pass.
- Water/Ice paradigm pass.
- Freeze status family.
- DoT identity split: Bleed, Burn, Poison, or other families.
- DoT cure support.
- Purge/Purity limited removal count.
- Temporary movement-type change support if Wood needs it.
- Temporary passive grants if Moon or other paradigms rely on them.

Exit criteria:

- Each Paradigm has at least one strong reference spell and a clear rule for making more spells.
- Debug/retired spells are either moved out of normal item access or clearly marked.

## Phase 7: AI And Enemy Behavior

Goal: make enemies use the established tools in ways that support encounter design.

Priority: Later, after player tools are readable.

Work items:

- AI performance optimization for enemy-turn start/end lag.
- AI understanding of Charge Polearm cycle charging.
- AI target valuation for Shade.
- AI use restrictions or heuristics for Reach Polearms, Quivers, Ofuda, Rescue/Warp, Toss/Shove/Pull, and status tools.
- AI role behavior tuning for Cointaker sub-objectives, Troublemaker pressure, Guard disruption, Archer positioning, Miko support, and Witch spell use.

Exit criteria:

- Enemies can express role identity without requiring every unit to have bespoke scripting.
- Enemy turn time is acceptable on the test map.

## Phase 8: Content Scaling

Goal: expand from reference material into the real campaign.

Priority: Do not rush.

Work items:

- Chapter 1-3 encounter drafts.
- Early-game item availability.
- Early promotion/criteria planning.
- Player roster onboarding order.
- Enemy species expansion beyond Human/Youkai.
- Additional roles and specialist enemies.
- Remilia-exclusive weapon line.
- Sakuya, Reimu, Meiling, Patchouli personal progression.
- Ofuda deity/theme expansion.
- Spellbook distribution and Patchouli memorization economy.

Exit criteria:

- The first real chapter cluster teaches the game's core promises without requiring debug assumptions.

## Do Not Touch Yet

These are valid ideas, but they should wait because they are likely to cause rework if built too early.

- Full 25-chapter stat scaling.
- Complete armory from basic to endgame.
- Large species roster tuning.
- Promotion bumps for every role.
- Full AI optimization before encounter goals are clear.
- Advanced elemental subfamilies before basic spell paradigms are tested.
- Large story/event scripting pass before the opening gameplay loop is stable.
- Late-game exclusive weapons before early-game weapon identity is proven.

## Open Design Questions

- What is the intended first playable map roster?
- Which reference items should appear in the first true chapter versus only in test maps?
- How quickly should the player gain access to Ofuda relocation?
- Should Patchouli's Spell Memorization exist before the first additional mage joins, or only when book competition becomes real?
- How strong should Remilia's day support role become before it stops feeling like a limitation?
- How much terrain Graze is acceptable before low-Hit weapons feel unreliable?
- Should enemy Cointakers be common enough to teach sub-objective pressure early?
- How often should Barrier Items appear before Guard identity feels properly supported?

## Next Concrete Step

Formalize the balance testing layer inside `combat_sandbox.tscn`.

The next development session should focus on controlled encounter pockets, not building another sandbox from scratch. `feature_workshop.tscn` proves most usable systems; `combat_sandbox.tscn` should make combat and balance questions easier to answer.
