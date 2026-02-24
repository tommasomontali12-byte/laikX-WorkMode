extends Window

func _ready():
	pass

func _process(delta: float) -> void:
	$topbar.size.x = $".".size.x + 10
	$browserContainer.size.x = $".".size.x
	$browserContainer.size.y = $".".size.y - 30
	$browserContainer/CefTexture.size = $browserContainer.size
	


func _on_refresh_pressed() -> void:
	pass

func _on_back_pressed() -> void:
	$browserContainer/CefTexture.go_back()
