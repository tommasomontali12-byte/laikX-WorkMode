extends Window

@export var action_name: String = "mouse_lock"

@onready var guidance: Label = $guidance
@onready var key_displayer: LineEdit = $keyDisplayer

var is_listening: bool = false

func _ready() -> void:
	# Show the currently saved key on startup
	_update_ui_text()

func _input(event: InputEvent) -> void:
	if not is_listening:
		return

	# Capture only the key press (ignoring mouse or joystick)
	if event is InputEventKey and event.is_pressed():
		_finalize_rebind(event)
		# Stop the input from bubbling up to other game systems
		get_viewport().set_input_as_handled()

func _finalize_rebind(new_event: InputEventKey):
	# 1. Update the Godot InputMap (Clears the old one entirely)
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	
	InputMap.action_erase_events(action_name) # The "vanishing" step
	InputMap.action_add_event(action_name, new_event)
	
	# 2. Update your Global Singleton
	Global.customMouseLockHotKey = new_event
	Global.isCustomMouseLockHotKeyEnabled = true
	
	# 3. Update UI
	is_listening = false
	_update_ui_text()
	guidance.text = "Hotkeys updated!"

# Call this when the user clicks the "Change Key" button/area
func start_rebind_mode():
	is_listening = true
	guidance.text = "Press any key..."
	key_displayer.text = "???"

func _update_ui_text():
	if Global.customMouseLockHotKey:
		key_displayer.text = Global.customMouseLockHotKey.as_text()
	else:
		key_displayer.text = "Not Bound"
