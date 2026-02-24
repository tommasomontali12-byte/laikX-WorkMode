extends GdCEF

func _ready():
	# Initialize CEF (required before creating browsers)
	initialize({})
	
	# Create a browser
	var browser = create_browser("https://github.com/Lecrapouille/gdCEF", $"../TextureRect", {})
	browser.set_name("my_browser")
