extends Control

# Folders to scan automatically
const ASSET_DIRS = [
	"res://assets/music/",
	"res://assets/backgrounds/",
	"res://assets/logos/",
	"res://assets/videos/"
]

# Max-Quality Storage
var music_lib: Dictionary = {}
var image_lib: Dictionary = {}
var video_lib: Dictionary = {}

var load_queue: Array[String] = []
var total_count: int = 0
var loaded_count: int = 0

@onready var status_label = $loadingLabel
@onready var bg_rect = $background

func _ready() -> void:
	_scan_all_assets()
	if load_queue.size() > 0:
		_start_async_loading()
	else:
		_finished_loading()

# Scans every folder in the list for EVERY file inside
func _scan_all_assets() -> void:
	for path in ASSET_DIRS:
		if DirAccess.dir_exists_absolute(path):
			var dir = DirAccess.open(path)
			dir.list_dir_begin()
			var file_name = dir.get_next()
			
			while file_name != "":
				if !dir.current_is_dir() and not file_name.ends_with(".import"):
					load_queue.append(path + file_name)
				file_name = dir.get_next()
			dir.list_dir_end()
	
	total_count = load_queue.size()

func _start_async_loading() -> void:
	for file_path in load_queue:
		# Threaded request handles large video files without freezing the UI
		ResourceLoader.load_threaded_request(file_path)

func _process(_delta: float) -> void:
	if load_queue.is_empty():
		return

	var current_path = load_queue[0]
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(current_path, progress)

	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			var resource = ResourceLoader.load_threaded_get(current_path)
			_categorize_resource(current_path, resource)
			
			load_queue.pop_front()
			loaded_count += 1
			status_label.text = "Assets Loaded: %d / %d" % [loaded_count, total_count]
			
			if load_queue.is_empty():
				_finished_loading()
				
		ResourceLoader.THREAD_LOAD_FAILED:
			push_error("Failed to load: " + current_path)
			load_queue.pop_front()

func _categorize_resource(path: String, res: Resource) -> void:
	var key = path.get_file().get_basename()
	
	if res is VideoStream:
		video_lib[key] = res
		print("Video Loaded: ", key)
	elif res is AudioStream:
		music_lib[key] = res
	elif res is Texture2D:
		image_lib[key] = res

func _finished_loading() -> void:
	status_label.text = "All Videos and Assets Ready!"
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://main_interface.tscn")
