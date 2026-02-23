extends Window

func _ready() -> void:
	#===INITAL=CHECKS=========
	if Global.isFullScreenEnabled:
		$settingsContainer/windowModeGroup/windowModeButton.select(1)
	else:
		$settingsContainer/windowModeGroup/windowModeButton.select(0)
	if Global.isCustomMusicEnabled:
		$settingsContainer/customMusicGroup/customMusicSwitch.button_pressed=true
	else:
		$settingsContainer/customMusicGroup/customMusicSwitch.button_pressed=false
	if Global.isMouseLockEnabled:
		$settingsContainer/mouseLockSwitch.button_pressed=true
	else:
		$settingsContainer/mouseLockSwitch.button_pressed=false
	if Global.isCustomMouseLockHotKeyEnabled:
		$settingsContainer/customMouseLockHotkeyGroup/customMouseLockHotHeyLabel.button_pressed=true
	else:
		$settingsContainer/searchEngineSwitch.button_pressed=false
	if Global.isBrowserEnabled:
		$settingsContainer/searchEngineSwitch.button_pressed=true
	else:
		$settingsContainer/searchEngineSwitch.button_pressed=false
	

#===CUSTOM=MUSIC=======
func _on_file_dialog_dir_selected(dir: String) -> void:
	if Global.isCustomMusicEnabled:
		customMusicSelection(dir)
	else:
		$settingsContainer/customMusicGroup/customMusicSwitch.button_pressed=true
		Global.isCustomMusicEnabled=true
		customMusicSelection(dir)

func _on_custom_music_button_pressed() -> void:
	$settingsContainer/customMusicGroup/customMusicButton/customMusicFileDialog.show()

func customMusicSelection(dir: String):
	Global.isCustomMusicEnabled=true
	Global.customMusicDirectory=dir
	print(dir)
	$settingsContainer/customMusicGroup/customMusicButton/AcceptDialog.show()

func _on_custom_music_switch_pressed() -> void:
	if Global.isCustomMusicEnabled:
		Global.isCustomMusicEnabled=false
		$settingsContainer/customMusicGroup/customMusicButton/AcceptDialog.show()
	else:
		Global.isCustomMusicEnabled=true
		$settingsContainer/customMusicGroup/customMusicButton/AcceptDialog.show()

#===MOUSELOCK==========
func _on_mouse_lock_switch_pressed() -> void:
	if Global.isMouseLockEnabled:
		$settingsContainer/mouseLockSwitch.button_pressed=false
		Global.isMouseLockEnabled=false
	else:
		$settingsContainer/mouseLockSwitch.button_pressed=true
		Global.isMouseLockEnabled=true
#===MOUSELOCK=CUSTOMHOTKEY==============

#===Close=Button=======
func _on_close_requested() -> void:
	$".".hide()


func _on_window_mode_button_item_selected(index: int) -> void:
	if index==0:
		Global.isFullScreenEnabled = false
	elif index==1:
		Global.isFullScreenEnabled = true
