# Feature Workshop Checklist

Static inspection target: `scenes/maps/feature_workshop.tscn`

This is a first-pass checklist based on the scene, its objective resources, and the map/object scripts it relies on. It is meant to give the manual test pass a head start, not replace it.

## Legend

- **Present:** The fixture/resource is placed or configured.
- **Provable:** The map should be able to prove this through manual play.
- **Partial:** Some of the pipeline exists, but the feature is incomplete or not fully represented.
- **Not Represented:** The feature may exist elsewhere, but this map does not currently provide a clean test.
- **Needs Manual Check:** Static inspection suggests it should work, but the result depends on runtime flow.

## Chapter Start And Setup

| Feature | Status | Evidence / Notes |
| --- | --- | --- |
| Map identity | Present | Root map title is `Feature Workshop`, chapter number is `1`. |
| Initial time of day | Present / Provable | Root map sets `hours = 7`; map splash should display initial time. |
| Opening scene | Present / Provable | `start_script` points to `seize_test_start_event.json`. |
| End scene | Present / Provable | `end_script` points to `seize_test_end_event.json`. |
| Map splash transition | Confirmed | Splash shows chapter number, title, and `7:00` start time. |
| Setup state | Confirmed | Opening event plays, then setup begins. |
| Deployment cells | Present / Provable | `Deployments` tile layer is populated. |
| Forced deployment | Confirmed | Sakuya and Remilia are forced, cannot be removed, and spawn in forced deploy spots. |
| Deployment count changes | Confirmed | Deployment cap is intentionally determined by placed deployment tiles plus forced deployment spots. This keeps the cap map-side and ensures the required spaces exist. |
| Over-cap deployment count | Not Applicable | A cap higher than available deployment spaces is prevented by the tile-driven setup. |

## Objectives

| Feature | Status | Evidence / Notes |
| --- | --- | --- |
| Seize victory | Present / Provable | Objective resource `seize_test.tres` uses `Seize`, `SeizeLayer`, `ALL`, and winning condition. |
| Seize tile fixture | Present / Provable | `SeizeLayer` has tile data. |
| Loss on mandatory unit death | Present / Provable | `remi_saku_death_loss.tres` uses `KillUnit`, `ANY`, and IDs `remilia`, `sakuya`. |
| Objective completion routing | Present / Provable | Objective completion calls back into map completion checks. |
| Objective UI wording | Partial | `BaseGameMap.get_objectives()` and `get_loss_conditions()` still return placeholder text. Need to recheck whether strings are full sentences or self-built UI fragments. |

## Core Play Systems

| Feature | Status | Evidence / Notes |
| --- | --- | --- |
| Pathing | Confirmed | Player and AI pathing are functioning in current tests. |
| Targeting | Confirmed | Targeting works for currently available actions. |
| Unit actions | Confirmed / Partial | Many actions work, but not every action exists or has a fixture yet. |
| Combat | Confirmed | Combat resolves for normal tested cases. |
| Unit death | Confirmed | Generic enemy, standard player unit, and essential player unit deaths process. Remilia death correctly entered game over after KillUnit objective fix. |
| Enemy AI | Confirmed / Partial | AI acts, paths, targets, and performs actions. Current AI state remains rudimentary and can expose support-action sequencing bugs. |
| Boss unit | Present / Provable | `Cirno` is placed with `isBoss = true`. |
| Boss Danmaku | Not Represented | No map Danmaku script is assigned for this sandbox pass. |
| Universal debug menu | Confirmed | Debug menu is part of the core HUD/game state, so any normal map has it. |

## HUD And Runtime Feedback

| Feature | Status | Evidence / Notes |
| --- | --- | --- |
| Clock HUD | Confirmed / Watch | Currently works, but has broken unexpectedly in the past and should stay on the regression list. |
| Focus viewer | Confirmed / Partial | Works for current units/terrain. Danmaku object mode is skeletal. Terrain third-parameter display can bleed past its asset instead of resizing. |
| Turn tracker | Confirmed | Extensively tested and functioning. |
| Debug menu | Confirmed | Available through the core HUD. |
| Camera controls | Confirmed / Tuning Needed | Functional but still wonky; mainly preference/fine-tuning rather than a blocking system issue. |
| Map splash time/title display | Confirmed | Routed through `MapManager._on_map_loaded()` and verified manually. |

## Terrain And Map Objects

| Feature | Status | Evidence / Notes |
| --- | --- | --- |
| Base terrain | Present / Provable | `Ground` tile layer is populated. |
| Terrain modifiers | Present / Provable | `Modifier` tile layer is populated. |
| Walls / blocking terrain | Present / Provable | Wall-like modifier data exists; breakable wall fixture is also placed. |
| Context hints | Confirmed / Design Unsettled | Tested during the last AI overhaul. Their final value and behavior as AI influencers is still undecided. |
| Door fixture | Present / Partial | A `Door` node is placed and `DoorTile.unlock()` emits the correct signal, but it is not visually represented clearly on the map. |
| Door interaction | Needs Manual Check | Action menu supports door targeting; needs a visible, convenient fixture. |
| Breakable wall fixture | Present / Awkward Fixture | `BreakableWall` is placed with `_hp = 5`, but its location is inconvenient for feature testing. |
| Chest fixture | Present / Needs Coverage | A chest fixture has been used for manual testing; add convenient fixture coverage for currency, item, and full-inventory cases. |
| Chest interaction pipeline | Usable / Needs Manual Overflow Check | Chest action routes directly from the action menu and MapManager handles opening, rewards, and turn completion. |
| Chest reward flow | Usable / Needs Polish | Currency/item prompts work; full inventory now opens a drop-only overflow inventory, with visual chest-item distinction deferred. |
| Passive special terrain | Usable / Needs Fixture Check | Shrine/HotSpring-style terrain can restore Life/Composure and charge Mon during the between-round step; needs convenient feature-workshop fixtures and manual value checks. |
| Active special terrain | Not Represented | Shops, visits, and other scene-driven terrain are not placed or in scope for this pass. |

## Events And Scenes

| Feature | Status | Evidence / Notes |
| --- | --- | --- |
| Opening event script | Present / Provable | Start JSON exists and contains a simple text event. |
| Victory/end event script | Present / Provable | End JSON exists and contains a simple text event. |
| Mid-chapter event triggers | Not Represented | `event_scripts` is empty and no trigger fixture was identified. |
| Camera manipulation for events | Not Represented | Supported elsewhere, but this map has no mid-chapter camera trigger fixture. |
| Narrative layer behavior | Recheck Later | Worked in older tests, but should be rechecked and reevaluated when scenes become the active task again. |

## Campaign And Persistence

| Feature | Status | Evidence / Notes |
| --- | --- | --- |
| Next map transition | Recheck Needed | Worked in older tests, but cannot be assumed after many changes. |
| Post-victory save flow | Needs Manual Check | `MapManager` routes victory through end script and transition save. |
| Map state save/load | Partial | Unit graveyard and some interactive state paths exist, but interactive save state appears incomplete. |
| Door/chest persistence | Partial | Chest/interactive state handling needs a focused review before treating it as proven. |

## Balance And Encounter Testing

| Feature | Status | Evidence / Notes |
| --- | --- | --- |
| Generic enemy testing | Present / Provable | Oni Troublemaker, Fairy Cointaker, Kuchisake Blade, and Human Miko units are placed. |
| Boss baseline testing | Present / Provable | Cirno is available as a non-Danmaku boss fixture. |
| Player unit stat testing | Provable | Balance can be tested by changing deployed player units and enemy resources. |
| Encounter pockets | Split Complete | Current combat layout was duplicated to `scenes/maps/combat_sandbox.tscn`, allowing `feature_workshop.tscn` to become a mechanics/feature test zone. |

## Current Bugs Found During Manual Pass

| Bug | Status | Notes |
| --- | --- | --- |
| AI friendly Ofuda/support action could leave combat UI up and then crash on bar update | Confirmed Fixed / Polish Later | AI Ofuda support no longer crashes or hangs the combat UI. Forecastless map pop text now gives readable feedback, but presentation needs later tuning. |
| Essential player death did not trigger game over | Confirmed Fixed | Remilia death entered game over after `KillUnit` was initialized by `BaseGameMap` and changed to normalize Unit/String death payloads into ids. |
| Game over state did not show old fail screen | Confirmed Fixed / Follow-Up Needed | `MapManager` routes `GAME_OVER` and `VICTORY` state changes to the existing GUI end screens once per map. Game-over screen displays and halts, but closing/return flow is not implemented. |
| Enemy combat UI scrolls can hang open without displayed effects | Open / Combat UI Polish | Enemy-unit combat UI scroll elements can remain open even when no effect entries are shown. |
| Focus viewer terrain third value overflows | Open | Third terrain parameter can bleed past the asset instead of causing the display to resize. |
| Door/breakable-wall fixtures are inconvenient | Open | Feature-proving copy of the map should make these systems easy to reach and see. |
| Generic enemy identification during debugging is awkward | Open | Runtime-generated generic IDs are useful, but crash reports need a readable way to distinguish duplicate generic scene instances, such as node name, level, role/species, or map fixture label. |

## First Manual Pass

1. Load `feature_workshop.tscn` from the normal game flow. Confirmed through New Game.
2. Confirm splash shows chapter number, title, and `7:00` start time. Confirmed.
3. Confirm opening event plays, then setup begins. Confirmed.
4. Confirm forced/deployable units and deployment count behave as expected. Confirmed.
5. Start the map and verify clock, focus viewer, turn tracker, debug menu, and basic camera controls. Confirmed, with tuning/overflow notes.
6. Verify player pathing, targeting, combat, unit actions, and enemy AI. Confirmed for available actions, with current AI/support-action bug noted.
7. Kill a generic enemy and a player unit to verify death handling. Confirmed for generic enemy and standard player death.
8. Test door interaction and breakable wall damage.
9. Complete the seize objective and confirm end event, victory flow, and transition/save behavior.
10. Trigger Remilia/Sakuya death and confirm the loss condition. Confirmed with Remilia. Game-over screen transition retested and works, but closing it has no follow-up flow yet.

## Follow-Up Fixtures

- Add dedicated chest fixture coverage for currency, normal item pickup, and full-inventory overflow.
- Add passive special terrain fixture coverage for Shrine Life restoration and HotSpring Composure restoration.
- Add one mid-chapter event trigger when event-trigger testing becomes the focus.
- Keep boss Danmaku in its own focused test until the boss pressure system is scoped.
- Use `scenes/maps/combat_sandbox.tscn` as the controlled encounter/balance sandbox copied from the proven feature-workshop layout.
- Edit `feature_workshop.tscn` into a feature-proving map with convenient fixtures for doors, breakable walls, chests, special terrain, and other system checks.
