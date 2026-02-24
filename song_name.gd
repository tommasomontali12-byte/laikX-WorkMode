# ScrollLabel.gd
extends Label

@export var scroll_speed: float = 50.0
@export var pause_duration: float = 1.5

var _scrolling := false
var _tween: Tween = null
var _box_width: float = 0.0

func _ready():
	position.x = 0
	clip_text = false
	autowrap_mode = TextServer.AUTOWRAP_OFF
	# Lock the label size to parent, don't let it grow
	size_flags_horizontal = Control.SIZE_FILL
	await get_tree().process_frame
	await get_tree().process_frame
	# Capture box width ONCE before text can resize anything
	_box_width = get_parent().size.x
	_check_overflow()

func _check_overflow():
	if _tween:
		_tween.kill()
		_tween = null

	position.x = 0
	_scrolling = false

	await get_tree().process_frame
	await get_tree().process_frame

	var text_width = get_minimum_size().x

	if text_width > _box_width:
		_scrolling = true
		_run_scroll_loop(text_width)

func _run_scroll_loop(text_width: float):
	if not _scrolling:
		return

	var end_x = -( text_width - _box_width)
	var duration = abs(end_x) / scroll_speed

	_tween = create_tween()
	_tween.tween_interval(pause_duration)
	_tween.tween_property(self, "position:x", end_x, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_interval(pause_duration)
	_tween.tween_property(self, "position:x", 0.0, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(_run_scroll_loop.bind(text_width))

func update_text(new_text: String):
	text = new_text
	await get_tree().process_frame
	await get_tree().process_frame
	_box_width = get_parent().size.x
	_check_overflow()
