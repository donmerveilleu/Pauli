# Paulina (gabrielballs)

Godot 4.3 project.

## Architecture

### Interactables & NPCs

- `interactables/Interactable.gd` — base `Area2D` for anything Paulina
  can interact with, and the single place the interact prompt is built.
  It builds its own collision shape, detects the player, and calls
  `interact()` on press (or immediately, if `auto_trigger` is set). The
  prompt itself is a small floating chip — a key cap (`interact_key_label`,
  "E" by default) next to an action label (`prompt_text`, e.g. "Talk to
  the Vendor") — that fades in and bobs gently while in range, styled to
  match `DialogueBox`'s parchment palette. Every interactable gets this
  for free just by extending `Interactable`; nothing should build its own
  prompt separately. `prompt_text` should just be the action ("Try the
  gate"), not "Press E to..." — the key cap already shows that.
- `characters/npcs/NPC.gd` — base class for characters whose `interact()`
  is just "show some dialogue lines" (`HabalDriver`, `Stranger`,
  `Tambay`, `Tindera`, `Vendor`). Extends `Interactable` and exposes
  exported fields — `npc_name`, portrait settings, and `first_lines` /
  `repeat_lines` arrays of `DialogueLine` resources — instead of every
  NPC script hardcoding its own dialogue calls. Subclasses that branch
  (choices, endings) override `interact()` but still use the inherited
  `say()` / `ask()` helpers so they stay just as decoupled from the UI.
- `characters/npcs/DialogueLine.gd` — a `Resource` with `speaker` and
  `text`, used to build the exported dialogue arrays above.
- `interactables/gate_puzzle/Gate.gd`, `interactables/TestSign.gd` —
  one-off interactables with their own branching `interact()`; not NPCs,
  but talk to the dialogue system the same decoupled way (see below).

### Event Bus

`globals/EventBus.gd` is an autoload (registered in `project.godot`)
that mediates between interactables and the UI, so neither side holds a
direct reference to the other:

- Interactables call `EventBus.say(...)`, `EventBus.ask(...)`,
  `EventBus.hide_dialogue()` — they never look up or call methods on a
  `DialogueBox` node directly.
- `ui/dialogue/DialogueBox.gd` listens on `EventBus`'s request signals
  and reports results back through `dialogue_advanced` /
  `dialogue_choice_made`, rather than exposing `say()`/`ask()` as a
  public API other nodes call into.
- `EventBus.dialogue_active` mirrors whether a line/choice is currently
  on screen, kept in sync by `DialogueBox`. `Player.gd` reads this
  directly to freeze movement during conversations, instead of finding
  the dialogue node itself.

Any new interactable-to-UI communication (e.g. a future phone UI) should
follow the same pattern: add signals/wrappers to `EventBus`, don't reach
into UI nodes from gameplay code or vice versa.

### Folder structure

Feature-based, not file-type-based:

- `characters/<name>/` — a character's script, sprites, and scene live
  together (e.g. `characters/npcs/vendor/Vendor.gd`,
  `Vendor.tscn`, `vendor_idle_sprite/`, `vendor_portrait_sprite/`).
- `levels/<NN_name>/` — a level's script/scene, plus that level's own
  `art/` and `audio/` subfolders for anything only that level uses.
  Nothing needs to live in a global assets folder just because of its
  file type.
- `assets/shared/` — only for assets genuinely reused across multiple
  levels/characters (a common font, a shared SFX, common UI chrome).
  If an asset is only used by one level or one character, it belongs
  next to that level/character instead, not here.
- `ui/<feature>/` — UI that isn't tied to a single level (dialogue,
  endings, the phone UI), grouped by UI feature rather than by file
  type.
- `globals/` — autoloads and static utility classes shared everywhere
  (`EventBus.gd`, `LevelUtils.gd`).
