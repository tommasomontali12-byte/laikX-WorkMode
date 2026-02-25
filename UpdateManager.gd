extends Node

# ─── Configuration ────────────────────────────────────────────────────────────
## Bump this string with every release you publish on GitHub.
const CURRENT_VERSION  := "1.0.0"
const GITHUB_API_URL   := "https://api.github.com/repos/tommasomontali12-byte/laikX-WorkMode/releases/latest"
const DOWNLOAD_DIR     := "user://updates/"

# ─── Signals ──────────────────────────────────────────────────────────────────
signal update_available(latest_version: String, download_url: String, release_notes: String)
signal update_not_available
signal download_progress(bytes_downloaded: int, total_bytes: int)
signal download_completed(file_path: String)
signal download_failed(error: String)

# ─── Internals ────────────────────────────────────────────────────────────────
var _http_check    : HTTPRequest
var _http_download : HTTPRequest
var _download_path : String = ""
var _poll_timer    : Timer


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(DOWNLOAD_DIR)
	)
	_setup_http_nodes()


func _setup_http_nodes() -> void:
	_http_check             = HTTPRequest.new()
	_http_check.use_threads = true
	add_child(_http_check)
	_http_check.request_completed.connect(_on_check_completed)

	_http_download                    = HTTPRequest.new()
	_http_download.use_threads        = true
	_http_download.download_chunk_size = 65536
	add_child(_http_download)
	_http_download.request_completed.connect(_on_download_completed)


# ─── Public API ───────────────────────────────────────────────────────────────

func check_for_updates() -> void:
	print("[UpdateManager] Checking for updates…")
	var headers := PackedStringArray([
		"User-Agent: laikX-WorkMode/%s" % CURRENT_VERSION
	])
	var err := _http_check.request(GITHUB_API_URL, headers)
	if err != OK:
		push_warning("[UpdateManager] Could not start update check: %s" % error_string(err))


func download_update(url: String) -> void:
	var file_name   := url.get_file()
	_download_path   = DOWNLOAD_DIR + file_name
	_http_download.download_file = ProjectSettings.globalize_path(_download_path)

	var headers := PackedStringArray([
		"User-Agent: laikX-WorkMode/%s" % CURRENT_VERSION
	])
	var err := _http_download.request(url, headers)
	if err != OK:
		download_failed.emit("Could not start download: %s" % error_string(err))
		return

	_start_progress_polling()


func apply_update_and_relaunch(downloaded_path: String) -> void:
	var global_path := ProjectSettings.globalize_path(downloaded_path)
	print("[UpdateManager] Applying update: ", global_path)

	match OS.get_name():
		"Windows":
			# Runs the downloaded .exe installer, then quits so it can replace the app
			OS.create_process(global_path, PackedStringArray(["/S"]))
		"Linux":
			OS.execute("chmod", ["+x", global_path])
			OS.create_process(global_path, PackedStringArray([]))
		"macOS":
			# Assumes a .dmg or standalone binary — adjust if you ship a .pkg
			OS.execute("chmod", ["+x", global_path])
			OS.create_process(global_path, PackedStringArray([]))

	get_tree().quit()


# ─── HTTP Callbacks ───────────────────────────────────────────────────────────

func _on_check_completed(
		result: int, response_code: int,
		_headers: PackedStringArray, body: PackedByteArray) -> void:

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_warning("[UpdateManager] Update check failed (HTTP %d)" % response_code)
		update_not_available.emit()
		return

	var json  := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		push_warning("[UpdateManager] Failed to parse release JSON")
		update_not_available.emit()
		return

	var data           : Dictionary = json.get_data()
	var latest_version : String     = (data.get("tag_name", "") as String).trim_prefix("v")
	var release_notes  : String     = data.get("body", "No release notes provided.")
	var download_url   : String     = _pick_asset_url(data)

	if latest_version.is_empty() or download_url.is_empty():
		update_not_available.emit()
		return

	if _is_newer(latest_version, CURRENT_VERSION):
		print("[UpdateManager] Update available: v%s" % latest_version)
		update_available.emit(latest_version, download_url, release_notes)
	else:
		print("[UpdateManager] Already on the latest version.")
		update_not_available.emit()


func _on_download_completed(
		result: int, response_code: int,
		_headers: PackedStringArray, _body: PackedByteArray) -> void:

	if _poll_timer:
		_poll_timer.stop()

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		download_failed.emit("Download failed (HTTP %d)" % response_code)
		return

	print("[UpdateManager] Download complete: ", _download_path)
	download_completed.emit(_download_path)


# ─── Progress Polling ─────────────────────────────────────────────────────────

func _start_progress_polling() -> void:
	if _poll_timer:
		_poll_timer.queue_free()
	_poll_timer              = Timer.new()
	_poll_timer.wait_time    = 0.25
	_poll_timer.timeout.connect(_poll_download_progress)
	add_child(_poll_timer)
	_poll_timer.start()


func _poll_download_progress() -> void:
	var downloaded := _http_download.get_downloaded_bytes()
	var total      := _http_download.get_body_size()
	download_progress.emit(downloaded, total)


# ─── Helpers ──────────────────────────────────────────────────────────────────

## Picks the right release asset for the current OS.
## Name your GitHub release assets like:
##   laikX-WorkMode-windows.exe   (or .zip)
##   laikX-WorkMode-linux.x86_64  (or .zip)
##   laikX-WorkMode-macos.zip
func _pick_asset_url(data: Dictionary) -> String:
	var assets : Array  = data.get("assets", [])
	var keyword : String = _os_keyword()

	for asset in assets:
		var name : String = (asset.get("name", "") as String).to_lower()
		if keyword in name:
			return asset.get("browser_download_url", "")

	# Fallback: return the first asset if nothing matched
	if not assets.is_empty():
		push_warning("[UpdateManager] No asset matched OS '%s', using first asset." % keyword)
		return assets[0].get("browser_download_url", "")

	return ""


func _os_keyword() -> String:
	match OS.get_name():
		"Windows" : return "windows"
		"Linux"   : return "linux"
		"macOS"   : return "macos"
		_         : return ""


## Returns true if version string `a` is strictly newer than `b`.
## Works with semantic versioning: "1.2.0" > "1.1.9"
func _is_newer(a: String, b: String) -> bool:
	var pa := a.split(".")
	var pb := b.split(".")
	for i in range(maxi(pa.size(), pb.size())):
		var va := int(pa[i]) if i < pa.size() else 0
		var vb := int(pb[i]) if i < pb.size() else 0
		if va != vb:
			return va > vb
	return false
