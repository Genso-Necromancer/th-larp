# Weapon Balance Notes

These notes are working direction, not final implementation. Older mentions of "Cele penalty" should be read as weapon weight: `max(weapon weight - Pwr, 0)` becomes the Cele penalty.

## Working Weapon Family Split

Weapon access is part of role identity. These are not universal options for every character. Books belong to caster roles, Gohei belong to priestess-like roles, Barrier Items belong to suitable physically defensive roles, and so on.

- Blade: self-protective reliability weapon. Blades keep the user functional through high accuracy, low weight, and light Barrier support rather than raw damage. They are the sidearm for units that need to attack safely, dodge cleanly, and avoid being punished too hard for a miss.
- Blunt: defense-breaking utility weapon. Blunts use high might, heavy weight, lower accuracy, and anti-defense or anti-equipment tools to crack units that expect normal attacks to bounce. They are forceful answers to armor, barriers, and entrenched defensive plans.
- Polearm: space-control weapon. Charge, Brace, and Reach make movement lanes, formations, and attack angles matter. Polearms are for vanguard pressure, second-line threat, and denying enemy rush patterns through positioning.
- Book/Scroll: active magical access. Scrolls usually provide one spell; books provide broader or stronger spell packages. The item is less a weapon body and more the spell access point, with passives used to tune or compete with the granted spell package.
- Gohei: priestess role-shaping sidearm. Gohei are actual weapons for Ofuda/priestess archetypes, but their identity comes from passives and role support rather than Blade-style innate reliability. They help define whether the wielder leans combat, support, cleansing, blessing, or hybrid play.
- Ofuda: expendable tactical rites. Ofuda are limited-use support, control, healing, and blessing tools that let priestess archetypes spend inventory resources to solve specific tactical problems. Their identity is payload choice, timing, and deity/theme expression rather than weapon stat competition.
- Bow: prepared ranged pressure. Bows threaten targets from controlled distances with range bands, while quivers change the nature of the shot at durability cost. They pressure Life, positioning, or enemy options while remaining vulnerable if approached.
- Knife: reckless target-removal weapon. Knives remove or compromise specific targets by undermining normal defenses through angle, timing, precision, status, true damage, crit pressure, or rule-bending rather than raw power.
- Natural: bespoke creature/personal attacks. Natural weapons are individual exceptions for bodies, monsters, or personal fighting styles rather than a standardized family with one shared stat curve.
- Barrier Item: defensive identity equipment. Barrier Items function like setting-appropriate shields and are the primary source of serious Barrier and/or Barrier Chance scaling for roles meant to express physical defensive identity.

## Polearms

Polearms should be treated as the space-control weapon family. They are not purely offensive or defensive; they reward positional awareness and make map geometry matter.

Baseline identity:
- Moderate Hit
- Moderate Dmg
- Moderate to high Weight depending subtype
- Little or no Barrier support
- Frequent access to Charge, Brace, or Reach

Sub-identities:
- Charge: rewards movement before attacking. Used for vanguard pressure, initiation, and open lanes.
- Brace: negates Charge bonus damage. Used for defensive lane control and anti-rush counterplay.
- Reach: uses exactly 2 range. Used for formation support, second-line pressure, and tricky targeting angles.

Draft intro melee stat lines:
- Blade: Mt 7, Hit 65, Wt 4, Bar 2, Bar.Ch 30
- Blunt: Mt 10, Hit 55, Wt 7
- Polearm (Charge): Mt 7+1H, Hit 60, Wt 5
- Polearm (Brace): Mt 9, Hit 60, Wt 6
- Polearm (Reach): Mt 8, Hit 60, Wt 9, Range 2
- Barrier (Small): Bar 4, Bar.Ch 40, Wt 2
- Barrier (Medium): Bar 9, Bar.Ch 40, Wt 7

Brace should be a constant narrow counter, not a "must not have moved" stance. It only answers Charge-style polearm pressure, so it can remain active without turning defenders into passive roadblocks.

Reach gives polearms their broader defensive identity. A Reach polearm defends by threatening space from behind an ally or across awkward hex angles, not by making the user harder to kill.

Meiling fits polearms because she is an active vanguard guard. She claims space, disrupts the enemy, and survives the consequences. A blade guard protects herself; a polearm guard protects tempo and positioning.

## Magic-Adjacent Equipment Triangle

Magic and spell-package notes now live in `magic_balance_notes.md`. The weapon-facing summary is:

- Book/Scroll = active magical access.
- Gohei = priestess role-shaping sidearm.
- Ofuda = expendable tactical payload.

Gohei reference body:
- Simple Gohei: Mt 6, Hit 65, Wt 4, Crit 0, Range 1, Barrier 0 / 0%, Dur 40

Barrier and Barrier Chance are reserved for Blades and Barrier Items, not Gohei. Gohei should earn their identity from passives and role-shaping support, while Crit remains a weapon-specific standout trait rather than a default family trait.

Current reference Gohei:
- Simple Gohei: neutral sidearm body with no passive. This is the baseline stat reference.
- Evasion Ward Gohei: Mt 3, Hit 55, Wt 4, Range 1, Dur 40. Grants +10 Graze while any enemy is adjacent. This shows Gohei minmaxing toward Ofuda/support survival at the cost of direct combat.
- Status Charm Gohei: Mt 5, Hit 60, Wt 4, Range 1, Dur 40. Grants +2 Cha while equipped. This reinforces status and resistance through a core stat instead of directly boosting effect chance or resist.
- Fairy Hunter Gohei: Mt 6, Hit 65, Wt 4, Range 1, Dur 40. Grants +10 Hit when targeting Fairy species. This shows combat-facing Gohei support without making Gohei into Blades.

Terminology:
- Slayer means an active effective-damage skill against a species.
- Hunter means a passive effect that turns on when targeting a species.

## Barrier Items

Barrier Items are not weapons, but they behave like weapon-family equipment. They establish physical defensive identity for suitable roles.

Role examples:
- Guard can use Barrier Items, allowing a unit like Meiling to pair non-defensive weapons with dedicated defensive equipment.
- Maid does not use Barrier Items, but can use Blades, gaining softer protection through accuracy, light weight, and Blade defensive traits.
- Miko gets neither Blades nor Barrier Items, relying more heavily on Graze and positioning for defense.

Barrier exists as chance-based mitigation so it shares some uncertainty with dodging, but it does not fully replace dodging. A dodge avoids all damage; a Barrier proc reduces damage and can combine with Def, terrain, and other sources. This lets tankier roles survive bad luck better than pure dodge units without making defense deterministic.

## Knives

Knives should not be defined primarily as debuff weapons. Debuffs can be part of their toolset, but the broader identity is reckless target removal by bypassing or undermining standard defenses.

Blunt weapons overcome defense through force and anti-equipment pressure. Knives overcome defense through angle, timing, precision, and rule-bending. A knife user can make a specific enemy less safe than they looked, but usually without Blade's defensive comfort, Polearm's space control, or Blunt's raw cracking power.

Common knife bypass traits:
- True Damage
- 1-2 range
- Debuff a stat on hit
- High Crit
- High Accuracy
- Grants Vantage
- Grants Canto
- Inflicts a status effect on hit

Most knives should have one major bypass trait. Lower-powered traits can be combined more freely, but stronger combinations should pay through might, durability, weight, accuracy, or availability.

Draft intro knife stat lines:
- Dagger: Mt 5, Hit 75, Wt 2, Range 1-2
- Silver Knife: Mt 4, Hit 70, Wt 2, Range 1, +2 true damage on hit

Possible knife sub-identities:
- Execution Knives: high crit, true damage, or finishing pressure.
- Disruption Knives: debuffs, status, or setup effects that make a hard target vulnerable to the rest of the team.
- Infiltration Knives: 1-2 range, Canto, Vantage, or high accuracy for reaching targets from awkward positions and surviving risky plays.

Knives can make CHA more prominent because many of their debuff/status effects interact with effect hit and resist systems.

## Bows

Bows should not be treated as simply "the 2-range weapon." Their identity is composure-efficient ranged pressure shaped by bow range bands and quiver loadout.

Bow identity pillars:
- Range bands
- Quiver modifiers
- Role/personal shot skills
- Composure efficiency

### Range Bands

Bows have an ideal range plus pressured edge ranges. The ideal range attacks normally. Close and Far ranges are still legal, but apply accuracy penalties.

Example range profiles:
- Yumi: Range 1-2, Far 3
- Longbow: Range 2, Close 1, Far 3-4
- Warbow: Range 2-3, Close 1, Far 4
- Named unique bow: Range 3, Close 2, Far 4-5

This makes bows flexible without making them perfectly flexible. Archers can threaten awkward distances, but positioning still matters.

### Quivers

Basic arrows are abstracted into normal bow attacks. A bow can always fire without a quiver equipped. Quivers represent special arrow preparations, not mandatory ammunition.

Quivers should modify bow attacks and always carry at least this universal downside:
- +1 bow durability loss when used

This creates the feeling of spending special ammunition without tracking arrow stacks or requiring a bag/ammo system. Stronger quivers can have additional downsides through might, accuracy, weight, target restrictions, or other tradeoffs.

Example quiver space:
- Fire Quiver: small bonus damage or a fire-themed effect; durability loss alone may be enough downside.
- Holy Water Quiver: effective pressure against undead/spirit-like species, with reduced might against other targets.
- Bodkin Quiver: lower might, but adds small true damage or partial defense/barrier bypass.
- Barbed Quiver: on hit, applies a movement, healing, or sustain penalty.
- Whistling Quiver: lower damage, but debuffs Hit, Eleg, Cha, or similar.
- Heavy Quiver: higher damage, but higher weight or lower Hit.

### Shot Skills

Shot skills should primarily live on roles or personal kits rather than bows. They represent archer training, personality, and role expression.

Examples:
- Pinning Shot
- Cover Shot
- Piercing Shot
- Heavy Shot
- Marked Shot
- Interrupt Shot

Shot skills can cost composure like other active skills. Quivers add itemized variety without adding composure cost.

### Bow Versus Spellcaster Identity

Spellcasters:
- High option density
- Active-skill dependent
- Often target Mag instead of Def
- More composure-hungry
- Usually cannot retaliate with spells

Archers:
- Have a stable normal attack
- Use range-band positioning
- Use quivers for special projectile tools at durability cost
- Use shot skills for composure-cost role expression
- Can retaliate with bows
- Are naturally composure-efficient when positioned well, because they avoid much of the frontline tax of being attacked, dodging, and tanking hits

Bows should feel like prepared ranged pressure, not physical spellcasting and not an ammo-management minigame.

### Discord Formating for Weapon table in dev logs
```text
|---- Item ---| Mt | Hit| Wt| Range | Barrier| Dur| Notes 
|-------------|----|----|---|-------|--------|----|-------
| Basic Blade | 7 -| 65 | 4 |-- 1 --| 2 / 30%| 40 |
| Basic Blunt |10 -| 55 | 7 |-- 1 --| 0 / 0% | 40 |
|ChargePolearm|7+1H| 60 | 5 |-- 1 --| 0 / 0% | 40 |
| BracePolearm| 9 -| 60 | 6 |-- 1 --| 0 / 0% | 40 | Grants `Brace`, negating incoming Charge bonus
| ReachPolearm| 8 -| 60 | 9 |-- 2 --| 0 / 0% | 40 | exact-2-range polearm
```
