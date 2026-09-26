# Cutscene Authoring Manual

This manual explains how to write `.cutscene` files for `DialogueOverlay`.

The first half is for scene authors: copy the template, declare the cast, write the scene, and use commands. The later sections are for deeper debugging, implementation details, and technical reference.

For a quick starting point, copy:

```text
res://scenes/cutscenes/templates/base.cutscene
```

Debugging reminder: press `F3` while running the dialogue overlay in debug mode to open the cutscene test loader.

## Quick Start

```text
@cast
remilia = Remilia Scarlet | Head Lady | remilia | neutral:th1
patchouli = Patchouli Knowledge | Librarian | patchouli | neutral:th2

@scene
with
	enter remilia left 0.75
	enter patchouli right 0.25
	focus remilia
	remilia: The night is young.
end

with
	focus patchouli
	anim patchouli question
	patchouli: That usually means trouble.
end

none: The mansion falls quiet.
```

## Creating A File

1. Copy the base template:

```text
res://scenes/cutscenes/templates/base.cutscene
```

2. Place the new `.cutscene` file in:

```text
res://scenes/cutscenes/scene_events/
```

3. Rename it for the scene you are writing.

4. Fill in `@cast`, then write the actual scene under `@scene`.

Basic rules:

- File extension is `.cutscene`.
- Comments start with `#`.
- Blank lines are ignored.
- Use lowercase cast keys in dialogue and commands.
- `none:` writes narration with no speaker name.

## Cast

The cast section declares every speaker the scene can use.

```text
@cast
remilia = Remilia Scarlet | Head Lady | remilia | neutral:th1, joy:remilia_joy
patchouli = Patchouli Knowledge | Librarian | patchouli | neutral:th2
minor = Minor Character
```

Write cast lines like this:

```text
key = Display Name | Title | Sprite Folder | sprite_alias:file_name
```

Fields:

- `key`: short lowercase name used by dialogue and commands.
- `Display Name`: name shown in the dialogue box.
- `Title`: optional title shown beside the name.
- `Sprite Folder`: character folder under `res://sprites/character/`.
- `sprite_alias:file_name`: optional expression sprites used by `swap`.

Practical sprite rule:

- Character talk sprites live in `res://sprites/character/[Sprite Folder]/scene_sprites/`.
- In the cast line, write only the file name without `.png`.
- Example: `neutral:th1` means `th1.png` in that character's `scene_sprites` folder.

If no sprite aliases are declared, the compiler tries `neutral:<key>_talk`.

## Scene Format

Everything after `@scene` is the script itself.

```text
@scene
remilia: Dialogue text.
none: Narration text.
```

Dialogue uses:

```text
speaker_key: Dialogue text.
```

Narration uses:

```text
none: Narration text.
```

Dialogue text stays on the same line as the speaker key for now.

## Command Timing

Use `with/end` when commands should happen together.

Attach commands to a dialogue line by placing the dialogue inside the block:

```text
with
	focus remilia
	anim remilia hop
	remilia: This line starts with the focus and hop.
end
```

Make commands happen before the next dialogue line by leaving dialogue outside the block:

```text
with
	focus remilia
	anim remilia hop
end
remilia: This line happens after the command beat finishes.
```

Only one dialogue line can be placed inside one `with/end` block.

Tabs are fine inside `with/end` blocks and are recommended for readability.

## Portrait Commands

These commands move, show, hide, or change portraits.

```text
enter remilia 0.75
enter remilia left 0.75
enter remilia right 0.75
show remilia at 0.75
slide remilia 0.50
exit remilia left
exit remilia right
hide remilia
swap remilia joy
```

What they do:

- `enter speaker position`: shows the portrait, starts offscreen left, and slides it to `position`.
- `enter speaker left/right position`: starts from the chosen offscreen side and slides to `position`.
- `show speaker at position`: shows the portrait and slides it to `position` from its current location.
- `slide speaker position`: moves the portrait from wherever it currently is to `position`.
- `exit speaker left/right`: slides the portrait offscreen. It does not hide it.
- `hide speaker`: immediately hides the portrait.
- `swap speaker alias`: changes the portrait art to a sprite alias from `@cast`.

Useful positions:

- `0.25`: left side.
- `0.50`: center.
- `0.75`: right side.
- `-0.25`: offscreen left.
- `1.25`: offscreen right.

## Animation Commands

Animations are visible movements or reactions for portraits.

```text
anim remilia shake
anim remilia hop
anim remilia double_hop
anim remilia interact
anim remilia toggle_fade
anim remilia question
```

What they do:

- `anim speaker shake`: shakes the portrait side-to-side.
- `anim speaker hop`: makes one small hop and plays the fwip sound.
- `anim speaker double_hop`: hops twice and plays the fwip sound.
- `anim speaker interact`: dips and bounces the portrait, useful for emphasis or a physical reaction.
- `anim speaker toggle_fade`: fades the portrait out if visible, or fades it in if hidden.
- `anim speaker question`: briefly shows the question-mark particle over the portrait.

There is also a lower-level slide animation:

```text
anim remilia slide 0.25
```

For normal writing, prefer:

```text
slide remilia 0.25
```

## Focus And Effects

Use these for visual focus, portrait brightness, text size, and a few special actions.

Common shorthand:

```text
focus remilia
dim patchouli
normal remilia
```

What they do:

- `focus speaker`: dims every other declared cast member and restores `speaker` to normal.
- `dim speaker`: darkens that portrait.
- `normal speaker`: restores that portrait to normal brightness and opacity.

Full effect syntax:

```text
effect loud
effect quiet
effect remilia portrait-sil
effect remilia portrait-normal
effect remilia dim
effect remilia zoom
effect remilia teleport 0.25
effect all dim
```

Common effects:

- `effect loud`: increases dialogue font size for the current text line.
- `effect quiet`: decreases dialogue font size for the current text line.
- `effect speaker portrait-sil`: turns the portrait fully black, like a silhouette.
- `effect speaker portrait-normal`: restores the portrait to normal brightness and opacity.
- `effect speaker dim`: same as `dim speaker`.
- `effect speaker zoom`: instantly scales the portrait up to `1.5x` and shifts it to stay framed. This is not animated and currently has no reset command.
- `effect speaker teleport position`: instantly moves the portrait to `position`.
- `effect all dim`: applies `dim` to every declared cast member.

Timing note: `loud` and `quiet` should be attached to the same dialogue beat they affect, usually inside `with/end`. The next text line resets to the default font size.

## Sound And Background

```text
sfx surprise
bg none
bg res://sprites/backgrounds/mansion_hall.png
```

- `sfx sound_name`: plays a sound effect.
- `bg none`: clears the background.
- `bg path`: sets the background texture.

## Common Patterns

Two-character conversation:

```text
with
	enter remilia left 0.75
	enter patchouli right 0.25
	focus remilia
	remilia: First line.
end

with
	focus patchouli
	patchouli: Reply line.
end
```

Change expression while speaking:

```text
with
	swap remilia joy
	focus remilia
	remilia: Much better.
end
```

Move an existing portrait mid-scene:

```text
with
	slide remilia 0.50
	remilia: Come closer.
end
```

Pre-beat before dialogue:

```text
with
	anim patchouli question
	sfx surprise
end
patchouli: Wait.
```

Big or small text:

```text
with
	effect loud
	remilia: HEY!
end

with
	effect quiet
	patchouli: ...inside voice.
end
```

Exit at scene end:

```text
exit remilia right
exit patchouli left
```

## Authoring Checklist

Before handing off a scene:

- The file is in `res://scenes/cutscenes/scene_events/`.
- Every speaking character has a cast entry.
- Every sprite alias used by `swap` is declared in `@cast`.
- Every `with` has a matching `end`.
- Each `with/end` block has no more than one dialogue line.
- `loud` and `quiet` are attached to the dialogue line they affect.
- Entrances, exits, and focus changes happen where you expect them to happen.

## Technical Reference

This section is for maintainers and anyone debugging the authoring system.

## Sprite Path Expansion

The author writes:

```text
remilia = Remilia Scarlet | Head Lady | remilia | neutral:th1
```

The compiler resolves `neutral:th1` to:

```text
res://sprites/character/remilia/scene_sprites/th1.png
```

If a sprite is missing, the compiler warns and falls back to the default portrait.

## Compiler Convenience

These are authoring conveniences. They are not all runtime commands.

- `focus speaker` compiles like `effect speaker speaker`.
- `effect speaker speaker` dims every other declared cast member and restores `speaker` to normal.
- `dim speaker` compiles like `effect speaker dim`.
- `normal speaker` compiles like `effect speaker portrait-normal`.
- `effect all effect_name` expands the targeted effect across every declared cast member.
- `enter speaker left/right position` compiles into portrait visibility, an instant teleport to the offscreen side, and a slide to `position`.
- `slide speaker position` compiles into a `slide` animation.

## Runtime Names

Known runtime animations:

- `slide`
- `shake`
- `hop`
- `double_hop`
- `interact`
- `toggle_fade`
- `question`

Known runtime effects:

- `portrait-sil`
- `portrait-normal`
- `dim`
- `loud`
- `quiet`
- `zoom`
- `teleport`
- `sound`

## Validation

The compiler reports errors and warnings for:

- Missing `@scene`.
- Unknown section.
- Unknown command.
- Dialogue before `@scene`.
- Unknown speaker key.
- Missing cast display name.
- Bad cast syntax.
- Bad numeric position.
- Unknown animation or effect name.
- Missing required command arguments.
- Missing sprite file path.
- More than one dialogue line inside one `with/end` block.

Errors include the source line when available. Unknown commands, speakers, effects, and animations try to suggest the nearest valid name.

## Production Notes

- Use `focus` for normal visual-novel speaker focus.
- Use explicit `dim` and `normal` when you want more directed staging.
- Use `with/end` for anything that should happen at the same time as a line.
- Keep sprite aliases short and expression-focused, such as `neutral`, `joy`, `angry`, or `tired`.
- Prefer command-only beats for pauses, entrances, exits, and reaction animations that should finish before the next line.
