extends Node

# ──────────────────────────────────────────────────────────────────────────────
# laikX WorkMode — Update Manager
# Autoload name: UpdateManager
# Reads version from Project Settings → Application → Config → Version
# ──────────────────────────────────────────────────────────────────────────────

var CURRENT_VERSION : String = ProjectSettings.get_setting("application/config/version", "0.0.0")

const GITHUB_API   : String = "https://api.github.com/repos/tommasomontali12-byte/laikX-WorkMode/releases/latest"
const DOWNLOAD_DIR : String = "user://updates/"

# ── Signals ───────────────────────────────────────────────────────────────────
signal update_available(latest_version: String, download_url: String, release_notes: String)
signal update_not_available
signal download_progress(bytes_downloaded: int, total_bytes: int)
signal download_completed(file_path: String)
signal download_failed(error_msg: String)

# ── Internals ─────────────────────────────────────────────────────────────────
var _http_check    : HTTPRequest
var _http_download : HTTPRequest
var _poll_timer    : Timer
var _download_path : String = ""


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(DOWNLOAD_DIR)
	)

	_http_check             = HTTPRequest.new()
	_http_check.use_threads = true
	add_child(_http_check)
	_http_check.request_completed.connect(_on_check_completed)

	_http_download                     = HTTPRequest.new()
	_http_download.use_threads         = true
	_http_download.download_chunk_size = 65536
	add_child(_http_download)
	_http_download.request_completed.connect(_on_download_completed)


# ── Public API ────────────────────────────────────────────────────────────────

func check_for_updates() -> void:
	print("[laikX Updater] Running v", CURRENT_VERSION, " — checking GitHub…")
	var headers := PackedStringArray(["User-Agent: laikX-WorkMode/%s" % CURRENT_VERSION])
	var err     := _http_check.request(GITHUB_API, headers)
	if err != OK:
		push_warning("[laikX Updater] Could not reach GitHub: %s" % error_string(err))


func start_download(url: String) -> void:
	_download_path               = DOWNLOAD_DIR + url.get_file()
	_http_download.download_file = ProjectSettings.globalize_path(_download_path)

	var headers := PackedStringArray(["User-Agent: laikX-WorkMode/%s" % CURRENT_VERSION])
	var err     := _http_download.request(url, headers)
	if err != OK:
		download_failed.emit("Could not start download: %s" % error_string(err))
		return

	_start_progress_polling()


func apply_and_relaunch(downloaded_path: String) -> void:
	var global_path := ProjectSettings.globalize_path(downloaded_path)
	print("[laikX Updater] Launching installer: ", global_path)
	# Runs the setup.exe, then quits so the installer can replace the running app
	OS.create_process(global_path, PackedStringArray([]))
	get_tree().quit()


# ── HTTP Callbacks ────────────────────────────────────────────────────────────

func _on_check_completed(
		result        : int,
		response_code : int,
		_headers      : PackedStringArray,
		body          : PackedByteArray) -> void:

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_warning("[laikX Updater] Check failed — HTTP %d" % response_code)
		update_not_available.emit()
		return

	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		push_warning("[laikX Updater] Could not parse release JSON")
		update_not_available.emit()
		return

	var data   : Dictionary = json.get_data()
	var tag    : String     = (data.get("tag_name", "") as String).trim_prefix("v")
	var notes  : String     = data.get("body", "No release notes provided.")
	var dl_url : String     = _find_setup_exe(data)

	if tag.is_empty():
		print("[laikX Updater] No release tag found.")
		update_not_available.emit()
		return

	if dl_url.is_empty():
		push_warning("[laikX Updater] No .exe asset found in release.")
		update_not_available.emit()
		return

	if _is_newer(tag, CURRENT_VERSION):
		print("[laikX Updater] Update found: v%s (have v%s)" % [tag, CURRENT_VERSION])
		update_available.emit(tag, dl_url, notes)
	else:
		print("[laikX Updater] Already up to date.")
		update_not_available.emit()


func _on_download_completed(
		result        : int,
		response_code : int,
		_headers      : PackedStringArray,
		_body         : PackedByteArray) -> void:

	if _poll_timer:
		_poll_timer.stop()

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		download_failed.emit("Download failed (HTTP %d)" % response_code)
		return

	print("[laikX Updater] Installer saved to: ", _download_path)
	download_completed.emit(_download_path)


# ── Progress Polling ──────────────────────────────────────────────────────────

func _start_progress_polling() -> void:
	if _poll_timer:
		_poll_timer.queue_free()
	_poll_timer           = Timer.new()
	_poll_timer.wait_time = 0.25
	_poll_timer.timeout.connect(_poll_progress)
	add_child(_poll_timer)
	_poll_timer.start()


func _poll_progress() -> void:
	download_progress.emit(
		_http_download.get_downloaded_bytes(),
		_http_download.get_body_size()
	)


# ── Helpers ───────────────────────────────────────────────────────────────────

# Finds the first .exe asset in the release — works whatever you name the file
func _find_setup_exe(data: Dictionary) -> String:
	var assets : Array = data.get("assets", [])
	for asset in assets:
		var name : String = (asset.get("name", "") as String).to_lower()
		if name.ends_with(".exe"):
			return asset.get("browser_download_url", "")
	return ""


# Returns true if version string `a` is strictly newer than `b`
# e.g. _is_newer("0.5.5", "0.5.4") == true
func _is_newer(a: String, b: String) -> bool:
	var pa := a.split(".")
	var pb := b.split(".")
	for i in range(maxi(pa.size(), pb.size())):
		var va := int(pa[i]) if i < pa.size() else 0
		var vb := int(pb[i]) if i < pb.size() else 0
		if va != vb:
			return va > vb
	return false
