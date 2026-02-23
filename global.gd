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
var is_dragging = false

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
				
				
#===dragSystem===============================
func _input(event):
	# 1. Check for the initial Left-Click while CTRL is held
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and Input.is_key_pressed(KEY_CTRL):
			is_dragging = true
			# "Consume" the input so buttons underneath don't click accidentally
			get_viewport().set_input_as_handled()
		else:
			is_dragging = false

	# 2. Handle the movement
	if event is InputEventMouseMotion and is_dragging:
		# We add the 'relative' movement of the mouse to the current window position
		var current_pos = DisplayServer.window_get_position()
		DisplayServer.window_set_position(current_pos + Vector2i(event.relative))
		
func _ready() -> void:
	load_data()
	
func _process(delta: float) -> void:
	save_data()
