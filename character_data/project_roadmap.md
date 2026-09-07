# Project Roadmap

This roadmap is for the whole game, not only balance. It is intentionally a scaffold: each milestone should become more accurate as systems are tested, cut, rewritten, or promoted from prototype to production.

## How To Use This

The roadmap is organized by playable milestones instead of departments. A milestone is complete when the game can do a new useful thing end-to-end.

Status labels:

- Done: works, tested, and polished.
- Usable: works, but needs cleanup, tuning, or polish.
- Partial: not missing, but not usable, or usable and not implemented everywhere it could be.
- Missing: not even started, or only dabbled with.
- Outdated: was once usable, but has fallen out of sync or is merely prototyped.
- Deferred: too soon to work on.
- Unknown: needs review before assigning status.

Priority rule:

When choice paralysis hits, work on the nearest milestone blocker that makes the game more playable, testable, or content-producible.

## Current Best Target

Current target: Reliable systems sandbox.

Why this target:

- `feature_workshop.tscn` already tests most usable end-to-end systems: setup, map splash, time, HUD, pathing, targeting, combat, AI, Seize victory, loss conditions, terrain, boss presence, unit death, and debug tools.
- The next highest-value work is formalizing what this map covers, adding missing fixtures where useful, and separating true blockers from tempting side paths.
- Balance remains one branch of this sandbox, but the target is broader than balance.

Hard blockers:

- Written systems sandbox checklist for `feature_workshop.tscn`.
- Clear list of which usable systems lack map fixtures.
- Forecast, tooltip, and targeting trust pass.
- Balance encounter pockets now belong in the duplicate/sibling `combat_sandbox.tscn` map.
- Known partial systems documented: chests, doors, special terrain, mid-chapter triggers, and boss Danmaku.

Related document:

- `development_roadmap.md` covers the balance/mechanics branch in more detail.
- `feature_backlog.md` holds focused feature groups that should not bloat this milestone roadmap.
- `systems_sandbox_notes.md` tracks what `feature_workshop.tscn` currently can and cannot test.

## Milestone 0: Foundation

Goal: the project can load, run a map, place units, and support basic tactical interaction.

Current read: mostly Done/Usable.

### Core Gameplay

| Area | Status | Notes |
|---|---|---|
| Hex grid movement | Usable | Pathing exists and supports terrain/move type costs. |
| Unit stats | Usable | Role + Species + personal direction exists; baseline pass is underway. |
| Combat resolution | Usable | Forecast/combat systems exist with many recent feature additions. |
| Turn flow | Usable | Player/enemy turn structure exists; some lag remains. |
| Composure | Usable | Core concept exists; tuning and chapter carryover pressure need testing. |
| Day/night cycle | Usable | Stat tables and time progression exist; Remilia/day-night identity still needs follow-up. |
| Boss/Danmaku foundation | Deferred | Boss pressure and Danmaku should be scoped when a real chapter/demo needs them. |

### Maps And Objectives

| Area | Status | Notes |
|---|---|---|
| Map loading | Usable | Maps can be loaded from scene selection. |
| Terrain data | Usable | Terrain values, tags, and movement costs exist. |
| Deployment cells | Usable | Deployment logic exists, including forced deployment support. |
| Objectives | Usable | Seize/objective framework exists; more objective types need review. |
| Victory/loss flow | Usable | Present but should be validated in real chapter prototypes. |
| Special terrain | Partial | Basic terrain exists; special terrain should be defined as a map-design tool when chapter prototypes need it. |
| Enemy reinforcements | Outdated | Needed for encounter variety; old/prototype flow needs review before relying on it. |

### UI And Tools

| Area | Status | Notes |
|---|---|---|
| Action menu | Usable | Functional enough for testing. |
| Forecast UI | Usable | Needs trust pass against current combat features. |
| Item tooltips | Usable | Expanded for recent equipment stats; needs consistency pass. |
| Debug tools | Usable | Debug controls and test resources exist; should be organized. |
| Map start menu | Usable | Loads selectable map scenes. |
| String routing | Partial | Text exists in multiple places; centralization should happen before content scales heavily. |

### Exit Criteria

- The project opens cleanly.
- A test map can be selected, loaded, played, won, lost, and returned from without manual recovery.
- Core unit movement, attacking, skill use, item use, and turn flow work.

## Milestone 1: Feature Workshop

Goal: one map that can test most, if not all, gameplay features.

Current read: mostly Usable through `feature_workshop.tscn`, but should be audited.

### Requirements

| Area | Status | Notes |
|---|---|---|
| Map scene construction workflow | Usable | Needs documentation for future content production. |
| Terrain and pathfinding | Usable | Needs tests for rough terrain, blocked cells, and movement types. |
| Special terrain examples | Missing/Unknown | Not required for basic test map unless a specific special-terrain mechanic is under test. |
| Unit placement | Usable | Includes player/enemy/NPC and undeployed storage behavior. |
| Deployment and forced deployment | Usable | Works enough to support current tests. |
| Basic combat | Usable | Needs regression checks after recent systems. |
| Victory objective | Usable | Seize exists; kill/other objective types need review. |
| Loss objective | Usable | Mandatory-unit death and map-specific conditions need validation. |
| Save during setup | Usable | Present in setup UI; campaign-level expectations remain later. |
| Basic AI action | Usable | AI can act but needs later optimization and smarter tool use. |
| Opening scene | Usable | `feature_workshop.tscn` has an opening scene. |
| Map splash | Usable | Chapter name and initial time of day are displayed. |
| Time and clock HUD | Usable | Time passes during play and the clock HUD is present. |
| Boss presence | Usable | Boss exists, but without Danmaku. |
| Doors/chests | Partial | Door/chest structure exists; chest rewards and overflow handling are usable, but fixture coverage and visual polish remain. |
| Mid-chapter triggers | Missing/Unknown | Camera manipulation exists, but no mid-chapter trigger fixture is set. |

### Exit Criteria

- A new developer can open the test map and understand what it is testing.
- The map can be played from setup to win/loss.
- Core systems fail visibly instead of silently breaking.

## Milestone 2: Balance Sandbox

Goal: controlled test environment for units, weapons, terrain, status, composure, and day/night.

Current read: partly covered by `feature_workshop.tscn`; needs formal encounter pockets/checklist in `combat_sandbox.tscn`.

### Requirements

| Area | Status | Notes |
|---|---|---|
| Player units | Usable | Reimu, Meiling, Patchouli, Sakuya, Remilia have testing stat lines. |
| Enemy units | Usable | Human/Youkai baseline roles exist; more species later. |
| Neutral units | Partial | Neutral faction/support exists enough to consider, but needs specific testing fixtures. |
| Reference weapons | Usable | All current weapon families have reference items. |
| Reference accessories | Usable | Barrier Items and Quivers exist. |
| Reference Ofuda | Usable | Heal, Warp, Rescue, Cure Sleep, Sleep exist. |
| Reference spell book | Usable | Spell references exist; some are debug/retired. |
| Sandbox checklist | Missing | Should define what each pocket is meant to prove. |
| Forecast feedback | Usable | Needs systematic comparison against live results, but the feedback layer exists. |
| Tooltips | Usable | Needs consistency pass for item stats/effects, but the core tooltip layer exists. |

### Exit Criteria

- Every reference family can be tested in one map or map suite.
- Balance notes can cite observed behavior rather than only projections.
- Major current mechanics have a simple regression path.

## Milestone 3: Setup And Roster Loop

Goal: the player can prepare for a chapter using roster, deployment, inventory, trade, and save tools.

Current read: Usable but needs productization.

### Requirements

| Area | Status | Notes |
|---|---|---|
| Roster screen | Usable | Exists; needs UX review and data validation. |
| Deployment toggle | Usable | Present in setup flow. |
| Forced deployment | Usable | Mandatory units supported. |
| Trade screen | Usable | Exists and has many focus/navigation paths. |
| Supply/convoy behavior | Usable | Present, but needs definition of final chapter setup expectations. |
| Item management | Usable | Needs rules for Barrier/Quiver/Accessory categories in setup. |
| Setup save | Usable | Needs validation with current SaveHub flow. |
| Character profile inspection | Usable | Exists; should expose enough info for planning. |

### Exit Criteria

- Player can enter setup, inspect units, deploy units, trade/manage inventory, save, and start map.
- Setup cannot create invalid equipment states.
- Undeployed units remain unavailable to normal map focus/interaction.

## Milestone 4: First Playable Chapter Prototype

Goal: a map that can string everything together in a reasonably playable state. This is independent of the systems themselves, and tracks the state of the prototype map.

Current read: Missing/Deferred until sandbox gives answers.

### Requirements

| Area | Status | Notes |
|---|---|---|
| Chapter objective | Missing | Pick one clean objective, likely simple but not empty. |
| Player roster | Missing | Decide exact starting roster and inventory. |
| Enemy roster | Missing | Use limited baseline roles/species. |
| Terrain plan | Missing | Teach movement, terrain, and threat lines without overload. |
| Opening event | Missing | Cutscene/event support exists, but the chapter-specific opening is not built. |
| Recruitment/talk event | Missing | Reimu concept needs talk/switch-side flow if this is Chapter 1. |
| Victory event | Missing | End scripts exist, but the chapter-specific victory event is not built. |
| Reward/loot | Missing | Needed if Cointaker/sub-objectives are introduced. |
| Loss conditions | Missing | Mandatory unit death, route fail, or objective fail. |

### Exit Criteria

- The chapter can be started from the title/start flow.
- The chapter has a beginning, playable middle, and end.
- The player can win and lose through intended conditions.
- The chapter teaches at least one core promise of the game.

## Milestone 5: Campaign Progression

Goal: chapters connect into a persistent campaign state.

Current read: Partial/Unknown.

### Requirements

| Area | Status | Notes |
|---|---|---|
| Persistent roster | Usable | PlayerData holds roster data, but campaign reliability needs review. |
| Carryover inventory | Usable | Needs save/load validation across maps. |
| Composure carryover | Usable | Core design requires between-chapter pressure and tuning. |
| Chapter transition | Outdated | `next_map` exists on maps; old flow needs real validation after current changes. |
| Save/load campaign | Usable | SaveHub exists; needs campaign-level test plan. |
| Death/graveyard handling | Usable | Normal death handling works; full graveyard mechanic is deferred. |
| Rewards and economy | Missing | Money, shops, drops, and rewards need design pass. |
| Shops | Missing | Shop access is part of the economy/campaign loop, not a balance-sandbox blocker. |

### Exit Criteria

- Finish Chapter A, carry state into Chapter B, save, quit, reload, and continue.
- Roster, inventory, level/exp, composure, deaths, and flags persist correctly.

## Milestone 6: Core Character Identity

Goal: mandatory/core characters have their defining mechanics in testable form.

Current read: Soon after sandbox.

### Requirements

| Character | Status | Missing/Needs Review |
|---|---|---|
| Reimu | Usable | Slayer progression, Miko/Gohei/Ofuda role teaching. |
| Meiling | Usable | Toss finalization, invalid-space behavior, Guard disruption tests. |
| Patchouli | Partial | Spell Memorization, Magical Counter. |
| Sakuya | Usable | Time-tool identity, target-killer transition, Locked Corpse tuning. |
| Remilia | Usable | Superior Vampire, day/night aura behavior, exclusive weapon identity. |

The broader playable roster is still likely around 20 characters, so this milestone only covers the current core set.

### Exit Criteria

- Each core character has one-page testing identity notes.
- Each has at least one map/sandbox scenario that proves their role.
- Their mechanics no longer depend on temporary testing equipment.

## Milestone 7: Content Production

Goal: creating new maps, units, items, scenes, and encounters becomes repeatable.

Current read: Missing/Unknown.

### Requirements

| Area | Status | Notes |
|---|---|---|
| Map creation checklist | Missing | Include terrain layers, deployment, objectives, events, AI personality, validation. |
| Unit creation checklist | Missing | Species, role, personal stats, inventory, skills/passives, portrait/sprite. |
| Item creation checklist | Partial | Item catalog exists; needs creator workflow and validation. |
| Encounter design template | Missing | Purpose, enemy roles, terrain, rewards, failure modes. |
| Balance logging template | Missing | Record expected/observed breakpoints. |
| Debug validation map suite | Missing | Sandbox can become first suite. |
| Asset naming conventions | Usable | Needs review before content scales, but existing naming is consistent enough to work from. |
| String/data conventions | Missing | Centralize IDs and text flow for UI, items, skills, objectives, and story before large content production. |
| Story scene creation checklist | Missing | Needed before narrative production scales beyond one-off test scenes. |

### Exit Criteria

- A new unit/item/map can be created from a checklist without relying on memory.
- Reference data and actual content stay separated.
- Debug/test content is easy to find and does not pollute real chapter availability.

## Milestone 8: First Demo Arc

Goal: a small set of legitimate chapters.

Current read: Deferred.

### Requirements

| Area | Status | Notes |
|---|---|---|
| 2-3 playable chapters | Missing | Needs actual chapter content, not only systems. |
| Setup/deployment between chapters | Usable | Setup flow exists and should be part of the demo arc. |
| Persistent roster/inventory/composure/EXP | Usable | Campaign persistence exists enough to test, but needs demo validation. |
| Core cast established | Partial | Current core cast exists; full demo cast and availability need confirmation. |
| Story scene before/after map | Usable/Outdated | Event support exists, but old scene flow needs review before production use. |
| Sub-objectives | Missing | Needed for loot pressure and optional tactical goals. |
| Day/night planning | Missing | Needs map content that makes time-state planning matter. |

### Exit Criteria

- A player can play from title through the demo arc without debug intervention.
- The demo teaches what kind of SRPG this is.
- The production process exposes realistic content costs.

## Milestone 9: Full Game Production

Goal: scale from demo to campaign.

Current read: Do not rush.

### Requirements

| Area | Status | Notes |
|---|---|---|
| Chapter list | Partial | Need rough 25-chapter spine. |
| Recruitment plan | Partial | Who joins when, mandatory/optional, roster pressure. Current rough roster target is around 20 playable units. |
| Playable roster plan | Usable | Track confirmed, likely, maybe, and cut candidates without fully statting everyone too early. |
| Species roster | Partial | Many ideas listed; only some should be implemented early. |
| Role roster | Partial | Baselines exist; additional roles later. |
| Promotion criteria | Missing | Planned but should wait for progression testing. |
| Economy curve | Missing | Item availability, money, shops, repair/replacement pressure. |
| Enemy scaling | Partial | Needs first balance pass and demo data. |
| Narrative structure | Partial | Event system exists; content plan needed. |
| Story writing | Partial | Needs chapter beats, recruitment scenes, support/story priorities, and a sustainable writing workflow. |
| Art | Partial | Needs asset scope and minimum viable style guide. |
| Audio | Partial | Needs asset scope and minimum viable style guide. |

### Exit Criteria

- Full chapter outline exists.
- Content pipeline can produce chapters at a predictable pace.
- Progression, economy, and roster rotation have been tested over multiple chapters.

## Milestone 10: Polish And Release Readiness

Goal: make the game shippable.

Current read: Far future.

### Requirements

| Area | Status | Notes |
|---|---|---|
| UX polish | Deferred | Menus, focus, tooltips, input comfort, readability. |
| Day/night presentation | Deferred | Shader tinting, sky/parallax, HUD warnings, and readable time-state feedback belong here unless needed earlier for testing. |
| Performance | Deferred | AI speed, map load, effect queues, turn transitions. |
| Bug pass | Deferred | Save/load, edge cases, softlocks, invalid states. |
| Accessibility/readability | Deferred | Fonts, contrast, icons, status clarity. |
| Audio/visual polish | Deferred | Animations, effects, UI sound, map presentation. |
| Difficulty modes/options | Deferred | Only after baseline difficulty is understood. |
| Packaging/export | Deferred | Godot export profiles, distribution, platform testing. |

### Exit Criteria

- Game can be played start to finish by someone other than the developer.
- Save files survive normal player behavior.
- Critical-path bugs are tracked and closed.
- Presentation is coherent enough to support the design.

## Cross-Cutting Systems

These are not milestones by themselves. They touch many milestones and should be advanced only when they unblock a milestone.

### Save/Load

- Setup save.
- Suspend save.
- Campaign save.
- Map state.
- Roster/inventory state.
- Death/graveyard state.
- Event/objective state.

### UI/UX

- Forecast.
- Tooltips.
- Unit profile.
- Item management.
- Deployment.
- Status tray.
- Turn tracker.
- Focus navigation.

### AI

- Basic attacks.
- Support skills.
- Objective pressure.
- Terrain preference.
- Role identity.
- Special tool use.
- Performance.

### Narrative/Event Tools

- Opening map scripts.
- Ending map scripts.
- Mid-map triggers.
- Recruitment/talk.
- Objective-triggered events.
- Cutscene editor/debugging.
- Story scene format and validation.

### Balance

- Unit stats.
- Weapon stats.
- Terrain values.
- Composure economy.
- Day/night.
- Status/proc rates.
- Enemy scaling.
- Item economy.

### Boss/Danmaku

- Boss encounter rules.
- Danmaku pattern pressure.
- Boss map readability.
- Interaction with movement, terrain, composure, and day/night.

## Not Yet Sorted

These need future sorting into milestones once their desired role is clearer.

- Exact Danmaku scope outside boss/reference encounters.
- Economy details beyond basic shops/funds.
- Repair or durability recovery, if any.
- Optional objectives and reward structure.
- Support/conversation systems, if any.
- Difficulty modes.
- Full art/audio production plan.
- Full species list.
- Full role list.
- Full playable roster details beyond the rough 20-character target.
- Promotion criteria and bumps.

## Immediate Next Questions

These are the questions most likely to improve this roadmap if answered next:

1. What should the first real playable chapter prove?
2. Is the balance sandbox separate from Chapter 1, or does Chapter 1 double as a tutorial/sandbox for the player?
3. What is the minimum campaign loop: Chapter 1 to Chapter 2 with setup, or a looser map-select prototype?
4. Which systems are already reliable enough that you do not want to revisit them unless they break?
5. Which systems feel most fragile or most likely to cause rework?

## Next Concrete Step

Formalize `feature_workshop.tscn` as the systems sandbox.

Start from the checklist for what `feature_workshop.tscn` already proves, then add focused fixtures for usable systems that are not represented yet. Do not build missing systems just to satisfy the checklist; mark them as partial or deferred until their feature group becomes the target.
