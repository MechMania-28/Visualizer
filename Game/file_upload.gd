# Code modified from https://github.com/Pukkah/HTML5-File-Exchange-for-Godot/
#  (linked addon only supports images... re-writing code to serve our purposes)

extends Control
signal file_loaded

var GameLog
onready var FileDia = $FileDialog
onready var ProgressText = $HBoxContainer/VBoxContainer/AspectRatioContainer/HBoxContainer/VBoxContainer/ProgressText
onready var ProgressBarNode = $HBoxContainer/VBoxContainer/AspectRatioContainer/HBoxContainer/VBoxContainer/ProgressBar
onready var Progress = $HBoxContainer
onready var Anim = $HBoxContainer/VBoxContainer/AspectRatioContainer/HBoxContainer/LoadSprite/AnimationPlayer
onready var LoadSprite = $HBoxContainer/VBoxContainer/AspectRatioContainer/HBoxContainer/LoadSprite
onready var uploadButton = $CenterContainer/WebUpload

var thread = Thread.new()
signal in_focus

# Called when the node enters the scene tree for the first time.
func _ready():
	FileDia.hide()
	Progress.hide()
	
	var _err = Global.connect("progress_text_changed",self,"_on_set_progress_text")
	_err = Global.connect("progress_changed",self,"_on_set_progress")
	_err = Global.connect("gamelog_verification_start",self,"_on_verification_start")
	_err = Global.connect("gamelog_verification_complete",self,"_on_verification_complete")
	_err = Global.connect("gamelog_verification_failed",self,"_on_verification_failed")
	
#	if Global.use_js:
#		_define_js()
#	else:
#		FileDia.show()
	 
	#uploadButton.show()
	auto_load_file()
	#popup(Rect2(0, 0, 500, 300))
	

var log_path = "C:/Users/Cameron/.mm28/downloadedlogs"
func auto_load_file():
	var d = Directory.new()
	var file = File.new()
	var file_path
	
	var looking = true
	while looking:
		d.open(log_path)
		d.list_dir_begin(true, true)
		
		file_path = log_path + "/" + d.get_next()
		if file.open(file_path,File.READ) != 0: 
			yield(get_tree().create_timer(5.0), "timeout")
		else:
			looking = false
	
	
	var json_result = JSON.parse(file.get_as_text())
	Progress.show()
	if json_result.error != OK:
		Global.progress_text = "Error: invalid file selected, cannot load file."
	else:
		file.close()
		OS.move_to_trash(file_path)
		GameLog = json_result.result
		Anim.play("loop")
		self.show()
		Progress.show()
		Global.verify_GameLog(json_result.result)
	

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
		
	


func web_load_file():
	
	if not Global.use_js:
		FileDia.show()
		return
	Progress.show()
	ProgressText.text = "Selecting a file..."
	# Call our upload function
	JavaScript.eval("upload();", true)
	# Wait for prompt to close and for async data load 
	yield(self, "in_focus")
	while not (JavaScript.eval("done;", true)):
		yield(get_tree().create_timer(.1), "timeout")
		# Check that upload wasn't canceled
		if JavaScript.eval("canceled;", true):
			return
			
	
	# Wait until full data has loaded
	var file_data: PoolByteArray
	while true:
		file_data = JavaScript.eval("fileData;", true)
		if file_data != null:
			break
		yield(get_tree().create_timer(0.1), "timeout")
	
	yield(get_tree(), "idle_frame")
	
	# Optionally check file type
	#var file_type = JavaScript.eval("fileType;", true)
	
	var gamelog_file = JSON.parse(file_data.get_string_from_utf8())
	if gamelog_file.error != OK:
		uploadButton.show()
		ProgressText.text = "Error: invalid file"
		return
	
	if gamelog_file.result == null:
		uploadButton.show()
		ProgressText.text = "Error: invalid file"
		return
	
	GameLog = gamelog_file.result
	Global.verify_GameLog(gamelog_file.result)


func _notification(notification: int):
	if notification == MainLoop.NOTIFICATION_WM_FOCUS_IN:
		emit_signal("in_focus")


func _on_verification_complete():
	Anim.get_animation("close").track_set_key_value(2, 0, LoadSprite.rect_rotation + 180)
	Anim.play("close")
	yield(get_tree().create_timer(1),"timeout")
	emit_signal("file_loaded", Global.GameLog, Global.Names)
	Progress.hide()
	self.hide()
	

func _on_verification_failed():
	ProgressText.text = "Error: " + ProgressText.text
	Progress.show()
	uploadButton.show()
	

func _on_verification_start():
	ProgressBarNode.max_value = Global.max_progress
	uploadButton.hide()

func _on_set_progress_text(new : String):
	ProgressText.text = new

func _on_set_progress(new : float):
	ProgressBarNode.value = new

# Pressing esc will open file select
func _unhandled_key_input(event):
	if event.is_action_released("ui_cancel"):
		popup()


var default: Rect2
func popup(_rect: Rect2 = default):
	# If built for web, FileDialog won't work
	
	if Global.use_js:
		web_load_file()
	else:
		FileDia.popup()

func _define_js():
	# Create global JS variables to store file upload state
	# Create input element to allow upload
	JavaScript.eval(
		"""
		var fileData;
		var fileType;
		var fileName;
		var canceled;
		var done;
		function upload(){
			fileData = null;
			fileType = null;
			fileName = null;
			canceled = false;
			done = false;
			var input = document.createElement('INPUT'); 
			input.setAttribute("type", "file");
			input.click();
			input.addEventListener('change', event => {
				if (event.target.files.length < 0){
					canceled = true;
				}
				var file = event.target.files[0];
				var reader = new FileReader();
				fileType = file.type;
				fileName = file.name;
				reader.readAsArrayBuffer(file);
				reader.onloadend = function (evt) {
					if (evt.target.readyState == FileReader.DONE) {
						fileData = evt.target.result;
						done = true;
					}
				}
			});
		}
		"""
	, true)


func _exit_tree():
	if thread.is_active():
		thread.wait_to_finish()

