extends AcceptDialog

func _on_confirmed() -> void:
	OS.set_restart_on_exit(true) 
	get_tree().quit()
