# Cutscene Authoring Format

Writer-facing manual:

```text
res://notes/cutscene_authoring_manual.md
```

Production starter template:

```text
res://scenes/cutscenes/templates/base.cutscene
```

This document defines the first-pass `.cutscene` authoring format. The `.cutscene` file is the writer-facing format; it compiles into the existing `Array[Dictionary]` event format consumed by `DialogueOverlay`.

## Core Rules

- File extension: `.cutscene`
- Runtime target: existing dialogue event array.
- Comments start with `#`.
- Blank lines are ignored.
- Speaker keys are lowercase/free-form identifiers chosen in `@cast`.
- `none:` is reserved for narration/no active speaker.
- Cast titles may be omitted.
- Sprite aliases are free-form.
- Missing or invalid sprite paths warn and fall back to the pre-established default talk sprite.

## Cast Format

```text
@cast
remilia = Remilia Scarlet | Head Lady | remilia | neutral:th1, joy:remilia_joy
patchouli = Patchouli Knowledge | Librarian | patchouli | neutral:th2
fairy = Nameless Fairy || fairy | neutral:fairy_talk
minor = Minor Character
```

Fields:

```text
key = Display Name | Title | Folder | alias:sprite_file, alias:sprite_file
```

Rules:

- `key` is what dialogue and commands use.
- `Display Name` appears in the textbox.
- `Title` appears in the title label and may be omitted.
- `Folder` resolves under `res://sprites/character/`.
- Sprite file aliases resolve under `scene_sprites`.
- If `Folder` is omitted, compiler tries the cast key as folder.
- If sprite aliases are omitted, compiler tries `neutral:<key>_talk`.

Sprite path expansion:

```text
remilia | neutral:th1
```

becomes:

```text
res://sprites/character/remilia/scene_sprites/th1.png
```

## Scene Format

```text
@scene
show remilia at 0.75
remilia: The night is young.

anim remilia hop
sakuya: That usually means trouble.

none: The mansion falls quiet.
```

## Dialogue

```text
speaker_key: Dialogue text.
none: Narration text.
```

Compiles to:

```gdscript
{"active_speaker": "speaker_key", "text": "Dialogue text."}
```

`none:` compiles to:

```gdscript
{"active_speaker": "none", "text": "Narration text."}
```

## Commands

These are the first-pass commands that need conversion.

### Background

```text
bg none
bg res://sprites/backgrounds/mansion_hall.png
```

Compiles to:

```gdscript
{"background": "none"}
{"background": "res://sprites/backgrounds/mansion_hall.png"}
```

### Portrait Visibility And Position

```text
enter remilia 0.75
enter remilia left 0.75
enter remilia right 0.75
show remilia at 0.75
slide remilia 0.50
hide remilia
exit remilia left
exit remilia right
swap remilia joy
```

Initial conversion:

- `enter` compiles to explicit portrait visibility, a `teleport` to the chosen offscreen side, then a `slide` animation to the destination.
- `enter speaker position` defaults to entering from the left.
- `enter speaker left/right position` chooses the side the portrait arrives from.
- `show` compiles to explicit portrait visibility plus a `slide` animation, without first staging offscreen.
- `slide` compiles to a `slide` animation only, moving the portrait from wherever it currently is.
- `hide` compiles to explicit portrait visibility off.
- `exit` slides a portrait offscreen to the chosen side. It does not hide the portrait.
- `swap` compiles to a portrait texture swap once runtime support exists.

Runtime-style output:

```gdscript
{"portrait_visibility": [{"target": "remilia", "visible": true}], "effects": [{"name": "teleport", "target": "remilia", "pos": -0.25}], "animations": [{"name": "slide", "target": "remilia", "pos": 0.75}]}
{"portrait_visibility": [{"target": "remilia", "visible": true}], "effects": [{"name": "teleport", "target": "remilia", "pos": 1.25}], "animations": [{"name": "slide", "target": "remilia", "pos": 0.75}]}
{"portrait_visibility": [{"target": "remilia", "visible": true}], "animations": [{"name": "slide", "target": "remilia", "pos": 0.75}]}
{"animations": [{"name": "slide", "target": "remilia", "pos": 0.50}]}
{"portrait_visibility": [{"target": "remilia", "visible": false}]}
{"animations": [{"name": "slide", "target": "remilia", "pos": -0.25}]}
{"animations": [{"name": "slide", "target": "remilia", "pos": 1.25}]}
{"portrait_swaps": [{"target": "remilia", "sprite": "joy", "path": "res://sprites/character/remilia/scene_sprites/remilia_joy.png"}]}
```

`portrait_visibility` and `portrait_swaps` are compiler-facing convenience fields supported by `DialogueOverlay`.

### Animation

```text
anim remilia slide 0.25
anim remilia shake
anim remilia hop
anim remilia double_hop
anim remilia interact
anim remilia toggle_fade
anim remilia question
```

Known runtime animation names:

- `slide`
- `shake`
- `hop`
- `double_hop`
- `interact`
- `toggle_fade`
- `question`

Compiles to:

```gdscript
{"animations": [{"name": "hop", "target": "remilia"}]}
{"animations": [{"name": "slide", "target": "remilia", "pos": 0.25}]}
```

### Effect

```text
effect loud
effect quiet
dim remilia
normal remilia
focus remilia
effect remilia portrait-sil
effect remilia portrait-normal
effect remilia dim
effect remilia speaker
effect all dim
effect remilia zoom
effect remilia teleport 0.25
```

Known runtime effect names:

- `portrait-sil`
- `portrait-normal`
- `dim`
- `loud`
- `quiet`
- `zoom`
- `teleport`
- `sound`

Compiler-only convenience effect names and targets:

- `dim speaker_key` is shorthand for `effect speaker_key dim`.
- `normal speaker_key` is shorthand for `effect speaker_key portrait-normal`.
- `focus speaker_key` is shorthand for `effect speaker_key speaker`.
- `effect speaker_key speaker` dims every other declared cast member and restores `speaker_key` to normal.
- `effect all effect_name` applies a targeted portrait effect to every declared cast member.

Compiles to:

```gdscript
{"effects": [{"name": "loud"}]}
{"effects": [{"name": "dim", "target": "remilia"}]}
{"effects": [{"name": "teleport", "target": "remilia", "pos": 0.25}]}
```

`effect remilia speaker` compiles to:

```gdscript
{"effects": [{"name": "dim", "target": "patchouli"}, {"name": "portrait-normal", "target": "remilia"}]}
```

`speaker` is not a runtime effect. It is authoring shorthand for visual-novel style focus.

### Sound

```text
sfx surprise
```

Compiles to:

```gdscript
{"effects": [{"name": "sound", "sound": "surprise"}]}
```

## Command Attachment

Some commands must be able to execute at the same time instead of as separate sequential beats.

If a dialogue line is inside `with/end`, it is attached to that command beat:

```text
with
  show remilia at 0.75
  anim sakuya hop
  effect loud
  remilia: Simultaneous setup happened as this line began.
end
```

Compiles to one dialogue event:

```gdscript
{
  "active_speaker": "remilia",
  "text": "Simultaneous setup happened as this line began.",
  "animations": [
    {"name": "slide", "target": "remilia", "pos": 0.75},
    {"name": "hop", "target": "sakuya"}
  ],
  "effects": [
    {"name": "loud"}
  ]
}
```

If no dialogue line is inside `with/end`, the block compiles to a command-only beat before whatever line comes next:

```text
with
  focus remilia
  anim remilia hop
end
remilia: This line happens after the command beat.
```

Only one dialogue line can be attached inside a single `with/end` block.

## Validation Expectations

The compiler should report line-numbered errors or warnings for:

- Missing `@scene`.
- Unknown section.
- Unknown command.
- Dialogue before `@scene`.
- Unknown speaker key.
- Missing cast display name.
- Bad cast syntax.
- Bad numeric position.
- Unknown animation/effect name.
- Missing required command arguments.
- Missing sprite file path, using default fallback.

Errors include the offending source line when available. Unknown commands, speakers, effects, and animations try to suggest the nearest valid name.

## Later Authoring Aid

Add a copyable base template:

```text
res://scenes/cutscenes/templates/base.cutscene
```

The template should include:

- Commented cast examples.
- Current command list.
- Known animation names.
- Known effect names.
- Sprite path expansion rule.
- Tiny working sample scene.
