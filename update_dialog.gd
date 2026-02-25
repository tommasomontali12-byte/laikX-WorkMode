extends Window

# ──────────────────────────────────────────────────────────────────────────────
# laikX WorkMode — Update Dialog
# Attach to the root Window node of UpdateDialog.tscn
# ──────────────────────────────────────────────────────────────────────────────

@onready var version_label : Label         = $VBoxContainer/VersionLabel
@onready var notes_box     : RichTextLabel = $VBoxContainer/NotesBox
@onready var progress_bar  : ProgressBar   = $VBoxContainer/ProgressBar
@onready var status_label  : Label         = $VBoxContainer/StatusLabel
@onready var update_btn    : Button        = $VBoxContainer/HBoxContainer/UpdateButton
@onready var skip_btn      : Button        = $VBoxContainer/HBoxContainer/SkipButton

var _download_url : String = ""


func _ready() -> void:
	# Window behaviour
	title            = "laikX WorkMode — Update Available"
	unresizable      = true
	always_on_top    = true
	exclusive        = true
	initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN

	hide()
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.hide()
	status_label.text = ""

	# Connect UpdateManager signals
	UpdateManager.update_available.connect(_on_update_available)
	UpdateManager.download_progress.connect(_on_download_progress)
	UpdateManager.download_completed.connect(_on_download_completed)
	UpdateManager.download_failed.connect(_on_download_failed)

	# Connect buttons
	update_btn.pressed.connect(_on_update_pressed)
	skip_btn.pressed.connect(_on_skip_pressed)
	close_requested.connect(_on_skip_pressed)


# ── Signal handlers ───────────────────────────────────────────────────────────

func _on_update_available(version: String, url: String, notes: String) -> void:
	_download_url      = url
	version_label.text = "laikX WorkMode v%s is available  —  you have v%s" % [
		version, UpdateManager.CURRENT_VERSION
	]
	notes_box.text     = notes
	status_label.text  = ""
	update_btn.text    = "Update Now"
	update_btn.disabled = false
	skip_btn.disabled   = false
	progress_bar.hide()
	popup_centered()


func _on_update_pressed() -> void:
	update_btn.disabled = true
	skip_btn.disabled   = true
	# Prevent closing while downloading
	close_requested.disconnect(_on_skip_pressed)

	progress_bar.value = 0.0
	progress_bar.show()
	status_label.text = "Connecting…"

	UpdateManager.start_download(_download_url)


func _on_download_progress(bytes_downloaded: int, total_bytes: int) -> void:
	if total_bytes > 0:
		progress_bar.value = float(bytes_downloaded) / float(total_bytes) * 100.0
		status_label.text  = "%s  /  %s" % [
			_fmt_bytes(bytes_downloaded), _fmt_bytes(total_bytes)
		]
	else:
		# Total unknown (chunked transfer) — show spinner-style text
		status_label.text = "Downloading…  %s received" % _fmt_bytes(bytes_downloaded)


func _on_download_completed(path: String) -> void:
	progress_bar.value = 100.0
	status_label.text  = "Download complete! Launching installer…"
	update_btn.text    = "Please wait…"

	await get_tree().create_timer(1.5).timeout
	UpdateManager.apply_and_relaunch(path)


func _on_download_failed(error_msg: String) -> void:
	status_label.text   = "⚠  " + error_msg
	update_btn.text     = "Update Now"
	update_btn.disabled = false
	skip_btn.disabled   = false
	# Re-enable X button
	if not close_requested.is_connected(_on_skip_pressed):
		close_requested.connect(_on_skip_pressed)


func _on_skip_pressed() -> void:
	hide()


# ── Helpers ───────────────────────────────────────────────────────────────────

func _fmt_bytes(b: int) -> String:
	if b < 1024:    return "%d B"    % b
	if b < 1048576: return "%.1f KB" % (b / 1024.0)
	return          "%.1f MB"        % (b / 1048576.0)
