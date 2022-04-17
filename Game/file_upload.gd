extends Control
signal file_loaded

var GameLog
onready var FileDia = $FileDialog
onready var ProgressText = $HBoxContainer/VBoxContainer/AspectRatioContainer/HBoxContainer/VBoxContainer/ProgressText
onready var ProgressBarNode = $HBoxContainer/VBoxContainer/AspectRatioContainer/HBoxContainer/VBoxContainer/ProgressBar
onready var Progress = $HBoxContainer
onready var Anim = $HBoxContainer/VBoxContainer/AspectRatioContainer/HBoxContainer/LoadSprite/AnimationPlayer
onready var LoadSprite = $HBoxContainer/VBoxContainer/AspectRatioContainer/HBoxContainer/LoadSprite

# Called when the node enters the scene tree for the first time.
func _ready():
	FileDia.popup(Rect2(0, 0, 500, 300))
	Progress.hide()
	
	var _err = Global.connect("progress_text_changed",self,"_on_set_progress_text")
	_err = Global.connect("progress_changed",self,"_on_set_progress")
	_err = Global.connect("gamelog_verification_start",self,"_on_verification_start")
	_err = Global.connect("gamelog_verification_complete",self,"_on_verification_complete")
	


func _on_FileDialog_file_selected(path):
	var file = File.new()
	file.open(path, file.READ)
	var json_result = JSON.parse(file.get_as_text())
	Progress.show()
	if json_result.error != OK:
		Global.progress_text = "Error: invalid file selected, cannot load file."
	else:
		file.close()
		GameLog = json_result.result
		Anim.play("loop")
		Global.verify_GameLog(json_result.result)
		
	

func _on_verification_complete():
	Anim.get_animation("close").track_set_key_value(2, 0, LoadSprite.rect_rotation + 180)
	Anim.play("close")
	yield(get_tree().create_timer(1),"timeout")
	emit_signal("file_loaded")
	Progress.hide()
	

func _on_verification_failed():
	ProgressText.text = "Error: " + ProgressText.text

func _on_verification_start():
	ProgressBarNode.max_value = Global.max_progress

func _on_set_progress_text(new : String):
	ProgressText.text = new

func _on_set_progress(new : float):
	ProgressBarNode.value = new
