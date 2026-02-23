extends LineEdit

var regex = RegEx.new()

func _ready():
	regex.compile("\\D")
	
	# UI Setup for MM:SS
	placeholder_text = "00:00"
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	max_length = 5 # MM:SS is 5 characters
	
	text_changed.connect(_on_text_changed)
	text_submitted.connect(_on_text_submitted)
	focus_exited.connect(_on_focus_exited)
	
	print("[TimeSelector] MM:SS Mode Ready.")

func _on_text_changed(new_text: String):
	var old_caret_pos = caret_column
	var old_len = text.length()
	
	# 1. Strip non-digits and limit to 4 digits (MMSS)
	var digits = regex.sub(new_text, "", true).left(4)
	
	# 2. Add colon at the 2nd position
	var formatted = ""
	for i in range(digits.length()):
		if i == 2:
			formatted += ":"
		formatted += digits[i]
	
	text = formatted
	
	# 3. Caret correction to stop the "jumpy" feeling
	var caret_offset = text.length() - old_len
	caret_column = old_caret_pos + caret_offset
	
	print("[Debug] Typing... MMSS Digits: ", digits)

func _on_text_submitted(_final_text: String):
	release_focus()

func _on_focus_exited():
	_finalize_and_save()

func _finalize_and_save():
	var raw_digits = regex.sub(text, "", true)
	
	if raw_digits.is_empty():
		Global.studyTime = 0
		return

	# 1. Pad RIGHT so "25" -> "2500" (25:00)
	var full_digits = raw_digits.rpad(4, "0")
	
	# 2. Extract Minutes and Seconds
	var m = full_digits.substr(0, 2).to_int()
	var s = clampi(full_digits.substr(2, 2).to_int(), 0, 59)
	
	# 3. Final UI Update
	text = "%02d:%02d" % [m, s]
	
	# 4. Save to Global (Minutes * 60 + Seconds)
	var total_seconds = (m * 60) + s
	Global.studyTime = total_seconds
	
	print("[Debug] Final MM:SS: ", text)
	print("[Debug] Total Seconds saved: ", total_seconds)
