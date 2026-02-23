extends Window

# UI References
@onready var back_btn = $bigContainer/hContainer/back
@onready var forward_btn = $bigContainer/hContainer/forward
@onready var reload_btn = $bigContainer/hContainer/reload
@onready var search_bar = $bigContainer/hContainer/searchBar
@onready var go_btn = $bigContainer/hContainer/go

# Browser Reference (Update path if you moved it into bigContainer)
@onready var cef = $bigContainer/CefTexture

func _ready():
	# Connect signals
	back_btn.pressed.connect(func(): cef.go_back())
	forward_btn.pressed.connect(func(): cef.go_forward())
	reload_btn.pressed.connect(func(): cef.reload())
	go_btn.pressed.connect(_load_from_search)
	search_bar.text_submitted.connect(_load_from_search)

func _load_from_search(text: String = ""):
	var url = search_bar.text
	if url.is_empty(): return
	
	# Simple check to add https if the user forgets
	if not url.begins_with("http"):
		url = "https://" + url
		
	cef.load_url(url)


func _on_close_requested() -> void:
	$".".hide()
