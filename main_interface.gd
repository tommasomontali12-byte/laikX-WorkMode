extends Control
var mouseLockActive = false
const fullscreenEnable = preload("res://assets/icons/fullscreen_24dp_E3E3E3_FILL0_wght400_GRAD0_opsz24.svg")
const fullscreenDisable = preload("res://assets/icons/fullscreen_exit_24dp_E3E3E3_FILL0_wght400_GRAD0_opsz24.svg")
var timerPaused = false
func _ready() -> void:
	print(Global.studyTime)
	$pip.hide()
		
	
	
func _on_start_button_pressed() -> void:
	$productivityTimer.wait_time = Global.studyTime
	$productivityTimer.start()
	Global.isProductivityActive=true
	$pip.show()
	$pip/backgroundVideo.play()
	if Global.isFullScreenEnabled:
		$pip/buttonsContainer/fullscreenToggle.icon = fullscreenDisable
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		$pip/buttonsContainer/fullscreenToggle.icon = fullscreenEnable


func _on_productivity_timer_timeout() -> void:
	$productivityTimer.stop()
	$pip/backgroundVideo.stop()
	$pip/musicPlayer/audioPlayer.stop()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$pip.hide()
	$finishedWindow.show()
	Global.isProductivityActive=false

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if Global.isProductivityActive:
		var time_left = $productivityTimer.time_left
		var total_time = $productivityTimer.wait_time
		# 1. Update the Text Label (MM:SS)
		@warning_ignore("integer_division")
		var minutes = int(time_left) / 60
		var seconds = int(time_left) % 60
		$pip/timeRemainingLabel.text = "%02d:%02d" % [minutes, seconds]
		# 2. Update the Progress Bar
		# We calculate the percentage (0 to 100)
		if total_time > 0:
			$pip/progressBar.value = (time_left / total_time) * 100

func _on_time_selector_editing_toggled(is_editing: bool) -> void:
	$pressEnterPopup.visible = is_editing

func _on_settings_pressed() -> void:
	$settings.show()


#===MOUSELOCK================================
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("lockMouse") and Global.isMouseLockEnabled and Global.isProductivityActive and mouseLockActive==false:
		toggle_mouse_capture()
		$pip/mouseLockDisclamer.show()
		mouseLockActive=true
	elif event.is_action_pressed("lockMouse") and Global.isMouseLockEnabled and Global.isProductivityActive and mouseLockActive:
		toggle_mouse_capture()
		$pip/mouseLockDisclamer.hide()
		mouseLockActive=false
	else:
		pass

func toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Releases the mouse and makes it visible again
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		# Locks the mouse to the center and hides it
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
#===TOP=BUTTONS====================
func _on_pause_button_pressed() -> void:
	if timerPaused:
		$productivityTimer.paused=false
		timerPaused=false
		$pip/paused.hide()
		$pip/musicPlayer/audioPlayer.stream_paused=false
	else:
		$productivityTimer.paused=true
		timerPaused=true
		$pip/paused.show()
		$pip/musicPlayer/audioPlayer.stream_paused=true

func _on_browser_button_pressed() -> void:
	pass

func _on_fullscreen_toggle_pressed() -> void:
	if Global.isFullScreenEnabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		$pip/buttonsContainer/fullscreenToggle.icon = fullscreenEnable
		Global.isFullScreenEnabled=false
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		$pip/buttonsContainer/fullscreenToggle.icon = fullscreenDisable
		Global.isFullScreenEnabled=true
	
func _on_close_pressed() -> void:
	if Global.isProductivityActive:
		
		$productivityTimer.stop()
		$pip.hide()
		$pip/musicPlayer/audioPlayer.stop()
		Global.isProductivityActive=false
	else:
		get_tree().quit()
