class_name DialogueBox
extends CanvasLayer

## Drop one of these into any level (DialogueBox.new() + add_child) and
## talk to it from anywhere via the EventBus autoload — never call
## methods on this node directly:
##
##   await EventBus.say("Tindera", "Sige, iha. Eto na, sukli ni nimo.")
##
##   var choice = await EventBus.ask("Paulina", "Unsa imong buhaton?",
##       ["Ignore and keep walking", "Turn around and respond"])
##
## This node also owns the shared "[E] ..." interact prompt bar (see
## EventBus.interact_prompt_requested) — it lives in the same bottom HUD
## sheet as the dialogue box, and the two share one visual language.
##
## Everything is built in code in _ready() rather than as a hand-authored
## .tscn, so there's nothing fragile to break when opened in-editor.

## Standard pixel-indie-game textbox: fully opaque, square-cornered,
## double-framed panel (a thick outer border, a gap, then a thin inner
## accent border — the classic retro-RPG "bezel" look) with a hard,
## non-antialiased edge. No translucency, no rounding, no soft blur
## shadows, no drag-handle nub (that reads like a modern mobile
## bottom-sheet, not a game textbox). Colors reuse the accents from the
## stamina bar (teal/amber) so the HUD reads as one consistent palette.
const PANEL_BG := Color("f0f0f4") # Light grey/off-white background
const BORDER_LIGHT := Color("1a1a24") # Dark outer border
const BORDER_TEAL := Color("4a4a59") # Muted dark grey inner border (replaces the green)
const TEXT_LIGHT := Color("111111") # Dark text for readability
const SPEAKER_GOLD := Color("d97725") # Adjusted speaker name color for light backgrounds
const BUTTON_BG := Color(0.16, 0.15, 0.2, 1.0)
const BUTTON_BORDER := Color(0.32, 0.3, 0.38)

const PIXEL_FONT_PATH := "res://assets/shared/fonts/Minecraft.ttf"

## Outer border thickness, gap to the inner accent border, and the inner
## accent border's own thickness — this is what builds the "frame within
## a frame" look instead of a single flat rectangle.
const OUTER_BORDER_WIDTH := 4
const FRAME_GAP := 5
const INNER_BORDER_WIDTH := 2

## Snappy box reveal: no opacity fades, just a hard, fast pop. Scales
## from Vector2.ZERO up past 1.0 (a slight overshoot) and settles back
## to Vector2.ONE — the classic "thunk" a retro textbox makes when it
## appears, done with a Tween using EASE_OUT + TRANS_BACK.
const POP_OVERSHOOT_DURATION := 0.1
const POP_SETTLE_DURATION := 0.06
const POP_OVERSHOOT_SCALE := Vector2(1.05, 1.05)

## Hiding is just as snappy but doesn't need the overshoot — a quick
## ease-in shrink back to nothing.
const HIDE_DURATION := 0.1

const PANEL_REST_TOP := -190.0
const PANEL_REST_BOTTOM := -30.0

## Typewriter speed, in characters per second.
const TYPE_CHARS_PER_SEC := 42.0

## The blocky "press to continue" arrow, drawn as a stair-stepped bitmap
## rather than a smooth vector/unicode glyph so it actually reads as
## pixel art at small sizes. 1 = filled pixel.
const _ARROW_ROWS := [
	"11111",
	"01110",
	"00100",
]
const _ARROW_PIXEL_SIZE := 4.0
const _ARROW_BLINK_INTERVAL := 0.35

signal advanced

var panel: PanelContainer
var _inner_frame: PanelContainer
var text_label: RichTextLabel
var choice_container: VBoxContainer
var portrait_rect: TextureRect
var _dialogue_tween: Tween

var interact_bar: PanelContainer
var _interact_key_label: Label
var _interact_text_label: Label
var _interact_bar_tween: Tween

var _continue_indicator: _PixelArrow
var _continue_blink_timer: Timer

var _pixel_font: FontFile
var _typing_tween: Tween
var _is_typing: bool = false


func _ready() -> void:
	layer = 10

	_load_pixel_font()
	_build_interact_bar()
	_build_dialogue_panel()

	# The only place this node talks to the outside world: listening on
	# EventBus rather than being looked up and called directly.
	EventBus.dialogue_line_requested.connect(_on_line_requested)
	EventBus.dialogue_choice_requested.connect(_on_choice_requested)
	EventBus.dialogue_hide_requested.connect(hide_box)
	EventBus.interact_prompt_requested.connect(_on_interact_prompt_requested)
	EventBus.interact_prompt_hide_requested.connect(_on_interact_prompt_hide_requested)


## Loaded once and reused everywhere so it only has to be disabled for
## antialiasing a single time — smoothed edges make a pixel font look
## blurry/off-model, so it's turned off at the resource level.
func _load_pixel_font() -> void:
	var loaded := load(PIXEL_FONT_PATH)
	if loaded is FontFile:
		_pixel_font = loaded
		_pixel_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	else:
		push_warning("DialogueBox: couldn't load pixel font at %s" % PIXEL_FONT_PATH)


func _unhandled_input(event: InputEvent) -> void:
	if not panel.visible or choice_container.get_child_count() > 0:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		# First press (Space/E) snaps the line fully into view if it's
		# still typing; only once it's fully shown does the same press
		# advance to the next line — the classic two-stage textbox.
		if _is_typing:
			_skip_typewriter()
		else:
			advanced.emit()


## True while a line or choice is on screen — Player.gd checks
## EventBus.dialogue_active (kept in sync from here) to freeze
## movement/interact input during conversations.
func is_dialogue_active() -> bool:
	return panel.visible


# ---------------------------------------------------------------------
# Dialogue panel
# ---------------------------------------------------------------------

func _build_dialogue_panel() -> void:
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 40
	panel.offset_right = -40
	panel.offset_top = PANEL_REST_TOP
	panel.offset_bottom = PANEL_REST_BOTTOM
	panel.visible = false
	panel.scale = Vector2.ZERO # collapsed until popped open
	add_child(panel)

	# Outer frame: thick, hard-edged, fully opaque border. This is the
	# whole box's silhouette.
	var outer_style := StyleBoxFlat.new()
	outer_style.bg_color = PANEL_BG
	outer_style.set_border_width_all(OUTER_BORDER_WIDTH)
	outer_style.border_color = BORDER_LIGHT
	outer_style.corner_radius_top_left = 0
	outer_style.corner_radius_top_right = 0
	outer_style.corner_radius_bottom_left = 0
	outer_style.corner_radius_bottom_right = 0
	outer_style.anti_aliasing = false # crisp pixel edge, no smoothing
	outer_style.set_content_margin_all(FRAME_GAP)
	panel.add_theme_stylebox_override("panel", outer_style)

	# Inner accent frame: a second, thinner border inset by FRAME_GAP,
	# with a transparent bg so the outer panel's color shows through the
	# gap as a thin "moat" between the two borders — the classic
	# double-bordered retro RPG textbox.
	_inner_frame = PanelContainer.new()
	var inner_style := StyleBoxFlat.new()
	inner_style.bg_color = Color(0, 0, 0, 0)
	inner_style.set_border_width_all(INNER_BORDER_WIDTH)
	inner_style.border_color = BORDER_TEAL
	inner_style.corner_radius_top_left = 0
	inner_style.corner_radius_top_right = 0
	inner_style.corner_radius_bottom_left = 0
	inner_style.corner_radius_bottom_right = 0
	inner_style.anti_aliasing = false
	inner_style.content_margin_left = 18
	inner_style.content_margin_right = 18
	inner_style.content_margin_top = 12
	inner_style.content_margin_bottom = 12
	_inner_frame.add_theme_stylebox_override("panel", inner_style)
	panel.add_child(_inner_frame)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_inner_frame.add_child(vbox)

	# speaker + line share one RichTextLabel ("Speaker — line text"), bold
	# name only, matching the reference layout.
	text_label = RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.scroll_active = false
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_label.add_theme_font_size_override("normal_font_size", 16)
	text_label.add_theme_font_size_override("bold_font_size", 16)
	text_label.add_theme_color_override("default_color", TEXT_LIGHT)
	if _pixel_font:
		text_label.add_theme_font_override("normal_font", _pixel_font)
		text_label.add_theme_font_override("bold_font", _pixel_font)
	vbox.add_child(text_label)

	choice_container = VBoxContainer.new()
	choice_container.add_theme_constant_override("separation", 6)
	vbox.add_child(choice_container)

	# Hidden whenever a line/choice is requested without a portrait, so
	# lines with no portrait still lay out exactly like before. Sits
	# outside the panel entirely (not inside its layout) so it can rise
	# above the top edge instead of being boxed in.
	portrait_rect = TextureRect.new()
	portrait_rect.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	portrait_rect.offset_right = -70
	portrait_rect.offset_left = -70 - 210
	portrait_rect.offset_bottom = -34
	portrait_rect.offset_top = -34 - 260
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST # crisp pixel art at this scale
	portrait_rect.visible = false
	add_child(portrait_rect)

	# The blocky "press to continue" indicator — a hard-blinking pixel
	# arrow docked to the box's bottom-right corner, replacing the old
	# drag-handle nub. Static position (the box no longer slides), so it
	# just needs to line up with the panel's own resting rect once.
	_continue_indicator = _PixelArrow.new()
	_continue_indicator.color = BORDER_TEAL
	_continue_indicator.rows = _ARROW_ROWS
	_continue_indicator.pixel_size = _ARROW_PIXEL_SIZE
	_continue_indicator.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	var arrow_size := Vector2(
		_ARROW_ROWS[0].length() * _ARROW_PIXEL_SIZE,
		_ARROW_ROWS.size() * _ARROW_PIXEL_SIZE
	)
	_continue_indicator.offset_right = -40 - FRAME_GAP - 6
	_continue_indicator.offset_bottom = PANEL_REST_BOTTOM - FRAME_GAP - 10
	_continue_indicator.offset_left = _continue_indicator.offset_right - arrow_size.x
	_continue_indicator.offset_top = _continue_indicator.offset_bottom - arrow_size.y
	_continue_indicator.visible = false
	add_child(_continue_indicator)

	_continue_blink_timer = Timer.new()
	_continue_blink_timer.wait_time = _ARROW_BLINK_INTERVAL
	_continue_blink_timer.timeout.connect(func():
		_continue_indicator.visible = not _continue_indicator.visible
	)
	add_child(_continue_blink_timer)


func _on_line_requested(speaker: String, text: String, portrait: Texture2D) -> void:
	_show(speaker, text, portrait)
	await advanced
	EventBus.dialogue_advanced.emit()


func _on_choice_requested(speaker: String, text: String, choices: Array, portrait: Texture2D) -> void:
	_show(speaker, text, portrait)

	var result := -1
	for i in choices.size():
		var btn := Button.new()
		btn.text = choices[i]
		btn.add_theme_color_override("font_color", TEXT_LIGHT)
		btn.add_theme_color_override("font_hover_color", PANEL_BG)
		if _pixel_font:
			btn.add_theme_font_override("font", _pixel_font)
			btn.add_theme_font_size_override("font_size", 16)
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = BUTTON_BG
		btn_style.set_border_width_all(2)
		btn_style.border_color = BUTTON_BORDER
		btn_style.corner_radius_top_left = 0
		btn_style.corner_radius_top_right = 0
		btn_style.corner_radius_bottom_left = 0
		btn_style.corner_radius_bottom_right = 0
		btn_style.anti_aliasing = false
		btn_style.content_margin_left = 12
		btn_style.content_margin_right = 12
		btn_style.content_margin_top = 6
		btn_style.content_margin_bottom = 6
		btn.add_theme_stylebox_override("normal", btn_style)
		var btn_hover_style := btn_style.duplicate()
		btn_hover_style.bg_color = BORDER_TEAL
		btn_hover_style.border_color = BORDER_TEAL
		btn.add_theme_stylebox_override("hover", btn_hover_style)
		btn.pressed.connect(func(): result = i)
		choice_container.add_child(btn)

	_stop_continue_blink()
	while result == -1:
		await get_tree().process_frame

	clear_choices()
	EventBus.dialogue_choice_made.emit(result)


func _show(speaker: String, text: String, portrait: Texture2D) -> void:
	EventBus.set_dialogue_active(true)
	_set_portrait(portrait)
	_set_line(speaker, text)
	clear_choices()
	_stop_continue_blink()
	_pop_dialogue_panel(true)
	_start_typewriter()


func _set_portrait(portrait: Texture2D) -> void:
	portrait_rect.texture = portrait
	portrait_rect.visible = portrait != null


## Bold speaker name, an em dash, then the line — "Armin — This place is
## so strange..." — all one paragraph, matching the reference layout.
func _set_line(speaker: String, text: String) -> void:
	var safe_speaker := speaker.replace("[", "[lb]")
	var safe_text := text.replace("[", "[lb]")
	text_label.text = "[color=#%s][b]%s[/b][/color] — %s" % [
		SPEAKER_GOLD.to_html(false), safe_speaker, safe_text
	]


## Reveals text_label's current text one character at a time rather than
## snapping it fully on screen. Uses RichTextLabel's own visible_characters
## counter, so the bbcode speaker-name tags above don't get counted or
## typed out themselves — only the actual rendered characters do.
func _start_typewriter() -> void:
	if _typing_tween and _typing_tween.is_valid():
		_typing_tween.kill()

	var total := text_label.get_total_character_count()
	text_label.visible_characters = 0
	_stop_continue_blink()

	if total <= 0:
		_is_typing = false
		_start_continue_blink()
		return

	_is_typing = true
	var duration := total / TYPE_CHARS_PER_SEC
	_typing_tween = create_tween()
	_typing_tween.tween_property(text_label, "visible_characters", total, duration) \
		.set_trans(Tween.TRANS_LINEAR)
	_typing_tween.tween_callback(func():
		_is_typing = false
		_start_continue_blink()
	)


func _skip_typewriter() -> void:
	if _typing_tween and _typing_tween.is_valid():
		_typing_tween.kill()
	text_label.visible_characters = text_label.get_total_character_count()
	_is_typing = false
	_start_continue_blink()


func clear_choices() -> void:
	for child in choice_container.get_children():
		child.queue_free()


func hide_box() -> void:
	_stop_continue_blink()
	_pop_dialogue_panel(false)
	clear_choices()
	EventBus.set_dialogue_active(false)


## Snappy box reveal — no modulate.a fades. Pops the panel open with a
## hard, fast scale: Vector2.ZERO to a slight overshoot (1.05) and back
## down to Vector2.ONE, via a Tween using EASE_OUT + TRANS_BACK. Hiding
## just shrinks straight back to zero, no overshoot needed.
func _pop_dialogue_panel(showing: bool) -> void:
	if _dialogue_tween and _dialogue_tween.is_valid():
		_dialogue_tween.kill()

	if showing:
		panel.visible = true
		panel.scale = Vector2.ZERO
		# Panel size is fixed by its anchors/offsets, but wait a frame so
		# the pivot is computed against the settled layout rather than a
		# stale/zero size.
		await get_tree().process_frame
		panel.pivot_offset = Vector2(panel.size.x / 2.0, panel.size.y)

		_dialogue_tween = create_tween()
		_dialogue_tween.tween_property(panel, "scale", POP_OVERSHOOT_SCALE, POP_OVERSHOOT_DURATION) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_dialogue_tween.tween_property(panel, "scale", Vector2.ONE, POP_SETTLE_DURATION) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_dialogue_tween = create_tween()
		_dialogue_tween.tween_property(panel, "scale", Vector2.ZERO, HIDE_DURATION) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_dialogue_tween.tween_callback(func():
			panel.visible = false
			# portrait_rect lives outside `panel` (so it can rise above
			# the box's top edge), so hiding the panel alone would leave
			# the last speaker's portrait stuck on screen.
			portrait_rect.visible = false
			portrait_rect.texture = null
		)


func _start_continue_blink() -> void:
	if choice_container.get_child_count() > 0:
		return
	_continue_indicator.visible = true
	_continue_blink_timer.start()


func _stop_continue_blink() -> void:
	_continue_blink_timer.stop()
	_continue_indicator.visible = false


# ---------------------------------------------------------------------
# Shared interact-prompt bar ("[E] Talk to the Vendor")
# ---------------------------------------------------------------------

## A small chip — a key cap next to the action text — docked to the
## bottom-center of the screen rather than hovering over whatever it's
## attached to in the world. Same flat, hard-edged, opaque pixel-game
## language as the dialogue box, just smaller: this is the "collapsed"
## state of that same bottom sheet.
func _build_interact_bar() -> void:
	interact_bar = PanelContainer.new()
	interact_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interact_bar.visible = false
	interact_bar.scale = Vector2.ZERO
	add_child(interact_bar)

	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.set_border_width_all(OUTER_BORDER_WIDTH)
	style.border_color = BORDER_LIGHT
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.anti_aliasing = false
	style.content_margin_left = 12
	style.content_margin_right = 14
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	interact_bar.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	interact_bar.add_child(row)

	var key_cap := PanelContainer.new()
	var key_style := StyleBoxFlat.new()
	key_style.bg_color = BORDER_TEAL
	key_style.set_border_width_all(2)
	key_style.border_color = PANEL_BG
	key_style.corner_radius_top_left = 0
	key_style.corner_radius_top_right = 0
	key_style.corner_radius_bottom_left = 0
	key_style.corner_radius_bottom_right = 0
	key_style.anti_aliasing = false
	key_style.content_margin_left = 8
	key_style.content_margin_right = 8
	key_style.content_margin_top = 1
	key_style.content_margin_bottom = 1
	key_cap.add_theme_stylebox_override("panel", key_style)

	_interact_key_label = Label.new()
	_interact_key_label.add_theme_font_size_override("font_size", 14)
	_interact_key_label.add_theme_color_override("font_color", PANEL_BG)
	if _pixel_font:
		_interact_key_label.add_theme_font_override("font", _pixel_font)
	key_cap.add_child(_interact_key_label)
	row.add_child(key_cap)

	_interact_text_label = Label.new()
	_interact_text_label.add_theme_font_size_override("font_size", 14)
	_interact_text_label.add_theme_color_override("font_color", TEXT_LIGHT)
	_interact_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _pixel_font:
		_interact_text_label.add_theme_font_override("font", _pixel_font)
	row.add_child(_interact_text_label)


func _on_interact_prompt_requested(key_label: String, prompt_text: String) -> void:
	_interact_key_label.text = key_label
	_interact_text_label.text = prompt_text
	interact_bar.visible = true
	# Width depends on the text, so let the container settle on its new
	# size before centering/popping it — that only lands after layout.
	await get_tree().process_frame
	_position_interact_bar()
	_pop_interact_bar(true)


func _on_interact_prompt_hide_requested() -> void:
	if not interact_bar.visible:
		return
	_pop_interact_bar(false)


func _position_interact_bar() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	interact_bar.position.x = (viewport_size.x - interact_bar.size.x) / 2.0
	interact_bar.position.y = viewport_size.y - interact_bar.size.y - 22.0
	interact_bar.pivot_offset = interact_bar.size / 2.0


## Same snappy pop as the dialogue panel — the bar is static now (it no
## longer slides up off-screen), it just scales in/out in place.
func _pop_interact_bar(showing: bool) -> void:
	if _interact_bar_tween and _interact_bar_tween.is_valid():
		_interact_bar_tween.kill()

	if showing:
		interact_bar.scale = Vector2.ZERO
		_interact_bar_tween = create_tween()
		_interact_bar_tween.tween_property(interact_bar, "scale", POP_OVERSHOOT_SCALE, POP_OVERSHOOT_DURATION) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_interact_bar_tween.tween_property(interact_bar, "scale", Vector2.ONE, POP_SETTLE_DURATION) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_interact_bar_tween = create_tween()
		_interact_bar_tween.tween_property(interact_bar, "scale", Vector2.ZERO, HIDE_DURATION) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_interact_bar_tween.tween_callback(func():
			interact_bar.visible = false
		)


# ---------------------------------------------------------------------
# Blocky pixel arrow (the "press to continue" indicator)
# ---------------------------------------------------------------------

## Draws a small bitmap shape as filled squares instead of a smooth
## vector/font glyph, so it reads as genuine pixel art rather than a
## scaled-up unicode triangle. `rows` is a list of equal-length strings;
## '1' = a filled pixel, anything else = empty.
class _PixelArrow extends Control:
	var rows: Array = []
	var pixel_size: float = 4.0
	var color: Color = Color.WHITE

	func _draw() -> void:
		for y in rows.size():
			var row: String = rows[y]
			for x in row.length():
				if row[x] == "1":
					draw_rect(Rect2(x * pixel_size, y * pixel_size, pixel_size, pixel_size), color)
