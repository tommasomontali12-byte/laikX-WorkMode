extends Node

#===Variables=====
var studyTime = 1500
var isProductivityActive = false
var isFullScreenEnabled = true
var isMouseLockEnabled = true
var isBrowserEnabled = true
var isCustomMouseLockHotKeyEnabled = false
var customMouseLockHotKey = ""
var customMusicDirectory = ""
var isCustomMusicEnabled = false

#===SAVING=SYSYEM===========
func save_data():
	var save_data = {
		#"model": model,
		"isCustomMusicEnabled": isCustomMusicEnabled,
		"customMusicDirectory": customMusicDirectory,
		"isMouseLockEnabled": isMouseLockEnabled,
		"isFullScreenEnabled": isFullScreenEnabled,
	}
	var file = FileAccess.open("user://save_data.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()

func load_data():
	if FileAccess.file_exists("user://save_data.json"):
		var file = FileAccess.open("user://save_data.json", FileAccess.READ)
		if file:
			var json_data = file.get_as_text()
			var json_instance = JSON.new()
			var result = json_instance.parse(json_data)
			file.close()
			if result == OK:
				var save_data = json_instance.get_data()
				#model = save_data.get("model", model)
				customMusicDirectory=save_data.get("customMusicDirectory", customMusicDirectory)
				isCustomMusicEnabled=save_data.get("isCustomMusicEnabled", isCustomMusicEnabled)
				isMouseLockEnabled=save_data.get("isMouseLockEnabled", isMouseLockEnabled)
				isFullScreenEnabled=save_data.get("isFullScreenEnabled", isFullScreenEnabled)
				
				

func _ready() -> void:
	load_data()
	
func _process(delta: float) -> void:
	save_data()
