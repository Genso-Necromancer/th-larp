# Systems Sandbox Notes

Current systems sandbox map: `scenes/maps/feature_workshop.tscn`

Current combat sandbox map: `scenes/maps/combat_sandbox.tscn`

The purpose of this map is to test the game's usable end-to-end systems in one controlled place. It began as a Seize objective test map, but currently functions as the closest thing to a whole-game systems sandbox.

## Currently Testable

- Opening scene.
- Map splash transition with chapter name and initial time of day.
- Setup state before map begins.
- Setup features, including deployment count changes.
- Passing of time during play.
- Clock HUD.
- Standard HUD/UI elements such as focus viewer and turn tracker.
- Seize objective completion.
- Loss conditions.
- Pathing.
- Targeting.
- Unit actions.
- Enemy AI.
- Base terrain such as grass.
- Terrain modifiers such as hills and walls.
- Boss unit without Danmaku.
- Balance testing through modifying placed enemies and player units.
- Deployable unit count adjustments.
- Camera manipulation for mid-chapter scenes.
- Enemy and player unit death.
- Universal debug menu through game state.

## Usable Systems Without Established Fixtures

These systems are at least partly usable, but `feature_workshop.tscn` does not currently contain a clean test fixture for them.

- Chests.
- Mid-chapter scene triggers.
- Camera manipulation during triggered events.
- Special terrain such as shops, shrines, or other map features.
- Encounter pockets for controlled balance testing. Current baseline moved to `combat_sandbox.tscn`.

## Known Partial Or Missing Behavior

- A door fixture exists in `feature_workshop.tscn`, but the door interaction should still be verified manually.
- A breakable wall fixture exists in `feature_workshop.tscn`, but object-damage flow should still be verified manually.
- Current door and breakable wall fixture placement is inconvenient for repeatable feature testing.
- Chests are not currently represented by a clean fixture in `feature_workshop.tscn`.
- Chests can be interacted with and visually change from unopened to opened.
- Chests do not yet complete the full reward flow for currency or item retrieval.
- Chest reward UI feedback is not established.
- Boss exists, but Danmaku boss pressure is not implemented in this sandbox.
- Special terrain is not placed.
- Mid-chapter camera/event triggers are not set up.
- Encounter pockets live in `combat_sandbox.tscn` so balance fixtures do not constantly disturb the reliable systems test.
- Deployment cap is intentionally map-authored through placed deployment tiles and forced deployment spots, ensuring the cap and available spaces stay synchronized.
- Objective and loss-condition text should be finished once the intended string format is rechecked.
- Focus viewer terrain display needs a sizing pass for terrain entries with a third parameter.
- Next-map transition worked in older tests, but needs a fresh regression pass.

## Current Read

`feature_workshop.tscn` can test almost everything currently usable. The next step is not to create a new sandbox from scratch, but to formalize what this map covers and add focused fixtures for systems that are usable but not currently represented.

First-pass checklist: `character_data/feature_workshop_checklist.md`

The current map split is:

- `feature_workshop.tscn`: stable systems/progression proof and future mechanics/feature test zone.
- `combat_sandbox.tscn`: duplicate of the proven combat layout for controlled encounter/balance testing.
- Future `feature_workshop` fixture edits: convenient fixtures for doors, chests, breakable objects, special terrain, event triggers, and similar system checks.

## Recommended Next Tasks

1. Create a test checklist for `feature_workshop.tscn`.
2. Add or document fixture zones for doors, chests, and special terrain when those systems are ready.
3. Add at least one mid-chapter trigger once story/event trigger testing becomes the target.
4. Keep boss Danmaku separate until boss mechanics are intentionally scoped.
5. Edit `feature_workshop.tscn` into a more convenient mechanics/feature test zone while preserving encounter testing in `combat_sandbox.tscn`.
