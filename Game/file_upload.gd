extends FileDialog
signal file_loaded

var GameLog


# Called when the node enters the scene tree for the first time.
func _ready():
	self.popup(Rect2(0, 0, 500, 300))


func _on_FileDialog_file_selected(path):
	var file = File.new()
	file.open(path, file.READ)
	var json_result = JSON.parse(file.get_as_text())
	if json_result.error != OK:
		print("JSON error")
		return null
	file.close()
	GameLog = json_result
	# throw up a loading screen here maybe
	get_tree().change_scene("res://game/Game.tscn")
	print("JSON done")
	
