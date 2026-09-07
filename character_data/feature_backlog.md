# Feature Backlog

This backlog holds focused feature groups that are too detailed for the whole-project roadmap, but too important to leave as loose notes.

Status labels:

- Roadmap: belongs directly in `project_roadmap.md` as a milestone requirement.
- Focused: belongs primarily in this backlog until design is clearer.
- Later: real feature, but not useful to plan in detail yet.

## Boss And Danmaku Systems

Roadmap status: Focused, later milestone impact.

Notes:

- Danmaku is likely a boss/map identity system rather than a baseline combat requirement.
- It should not block the balance sandbox unless a current test map specifically needs it.
- It should become roadmap-blocking once the first chapter/demo arc needs a boss or bullet-pattern map pressure.

Potential tasks:

- Decide whether Danmaku is boss-only, map-objective pressure, environmental hazard, or all of these.
- Define what a "boss turn" means in relation to normal unit turns.
- Define how Danmaku interacts with terrain, movement, composure, damage, and avoid/graze.
- Build one reference boss encounter when the demo arc needs it.

## Day/Night Presentation

Roadmap status: Focused, presentation branch.

Notes:

- The mechanical day/night system is usable enough for balance testing.
- Visual day/night clarity is important because the system affects planning, especially Remilia.
- Shaders and parallax sky should be treated as presentation solutions, not roadmap goals by themselves.

Potential tasks:

- Learn enough shader workflow to tint maps by time of day.
- Prototype a visible day/night overlay or shader.
- Prototype a parallax sky background if maps support visible sky or backdrop layers.
- Decide how the player reads approaching dawn/night from the HUD and map visuals.

## Economy And Shops

Roadmap status: Roadmap and Focused.

Notes:

- Shops belong in the campaign loop because they affect carryover, item availability, money, and roster preparation.
- They should not block the balance sandbox unless item access cannot be tested through debug distribution.

Potential tasks:

- Define money/funds source.
- Define shop access timing: setup menu, map tile, intermission, or all.
- Define whether shops sell fixed inventory, chapter inventory, limited stock, or rotating stock.
- Define repair/durability recovery separately before assuming shops solve it.
- Create a reference shop only after the campaign loop needs real item acquisition.

## Map And Encounter Features

Roadmap status: Roadmap and Focused.

Notes:

- Special terrain and enemy reinforcements are map-design tools.
- They belong in real chapter prototypes and demo arc planning, not the earliest balance sandbox unless specific mechanics need testing.
- Special terrain has two broad groups: passive tiles such as Shrine/HotSpring that apply restoration and Mon cost during the between-round step, and active tiles such as Shop/Visit that transition into a shop UI or narrative scene.

Potential tasks:

- Define special terrain categories: damage, healing, movement, defense, visibility, day/night-sensitive, objective-linked.
- Build reference passive and active special terrain fixtures only when a map needs them.
- Define reinforcement triggers: turn count, region trigger, objective trigger, death trigger, time-of-day trigger, story trigger.
- Define reinforcement fairness rules: warning, spawn placement, same-turn action, and player information.

## Narrative And Story Scenes

Roadmap status: Roadmap and Focused.

Notes:

- Story writing is a whole-project content responsibility.
- Story scene systems are production tooling and must be good enough before real chapter production scales.
- The first playable chapter only needs minimal story flow; the demo arc needs reliable story scene tools.

Potential tasks:

- Define story format: VN-style scenes, map events, narration cards, dialogue-only, or mixed.
- Audit current cutscene/event tooling.
- Build one opening scene, one mid-map event, and one victory scene as reference material.
- Create a story scene checklist: speakers, portraits, camera, music, flags, map transition, skip/debug controls.
- Draft chapter-level story beats only after the first chapter gameplay target is chosen.

## Recruitment And Talk

Roadmap status: Roadmap and Focused.

Notes:

- Recruitment is an extension of Talk, but it touches factions, AI, map objectives, story flags, roster persistence, and unit deployment state.
- It should be tested first with one unique unit, likely Reimu if that remains her chapter concept.

Potential tasks:

- Define Talk command targeting and availability.
- Define recruitment conditions: speaker, target, chapter flag, enemy state, turn, objective state.
- Define side-switch behavior: faction change, action state, AI removal, deployment status, inventory handling.
- Define how recruited units persist into roster after chapter end.
- Create one reference recruitment event before scaling optional recruitment.

## Strings And Data Organization

Roadmap status: Roadmap, production pipeline.

Notes:

- Consolidation and centralization of strings is a production-pipeline task.
- It becomes more urgent before serious story, item, skill, and chapter content scaling.

Potential tasks:

- Audit where strings currently live: item names, skill names, terrain names, UI text, story text, objective text.
- Decide whether all strings route through `StringGetter`, data files, CSV/JSON, or another central source.
- Establish IDs and naming conventions.
- Add validation for missing string IDs.
- Keep debug/test strings clearly marked.

## Playable Roster Planning

Roadmap status: Roadmap and Focused.

Notes:

- The current five core units are only the first testing set.
- A final playable roster around 20 units changes recruitment pacing, chapter design, role coverage, deployment pressure, and composure rotation.
- Do not fully stat all 20 units before the baseline and demo loop are proven.

Potential tasks:

- Maintain a candidate roster list with status: confirmed, likely, maybe, cut.
- Record intended role/species/weapon access for each candidate.
- Record rough join timing and recruitment method.
- Identify mandatory units versus optional units.
- Identify which characters are needed for the first demo arc.
- Delay final growth/stat polish until the core balance pass has real play data.
