extends MarginContainer
signal timeline_changed(value)
signal pause_toggled(paused)
signal stepped_forward
signal stepped_backward
signal timeline_interaction(clicked)

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var p1panel = $UI/HBoxContainer/LeftSideInfo/P1Panel
onready var p2panel = $UI/HBoxContainer/LeftSideInfo/P2Panel
onready var p3panel = $UI/HBoxContainer/RightSideInfo/P3Panel
onready var p4panel = $UI/HBoxContainer/RightSideInfo/P4Panel
onready var player_panels = [p1panel, p2panel, p3panel, p4panel]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Timeline_value_changed(value):
	emit_signal("timeline_changed", value)


func _on_PlayButton_toggled(button_pressed):
	emit_signal("pause_toggled", button_pressed)


func _on_ForwardButton_pressed():
	emit_signal("stepped_forward")


func _on_BackButton_pressed():
	emit_signal("stepped_backward")


func _on_FileDialog_file_loaded(new_gamelog):
	$UI/HBoxContainer/TimeControls/Timeline.max_value = len(new_gamelog) - 1
	#for i in range(4):
		#player_panels[i].set_name(new_gamelog["GameLog"]["Main"]["Info"][i])
	pass

func force_pause(paused):
	$UI/HBoxContainer/TimeControls/PlayButton.pressed = not paused


func update_turn_num(turn):
	$UI/HBoxContainer/TimeControls/Panel/VBoxContainer/Label2.text = str(turn)
	$UI/HBoxContainer/TimeControls/Timeline.value = turn


func update_health(player, new_health):
	player_panels[player].update_health(new_health)

func update_player_stats(stat_array):
	for i in range(4):
		player_panels[i].update_health(stat_array[i]["health"])
		# player_panels[i].update_points(stat_array[i]["Points"]) #not in test json
		player_panels[i].update_gold(stat_array[i]["gold"])
		player_panels[i].update_item(stat_array[i]["item"])
		player_panels[i].update_class(stat_array[i]["class"])
		# update speed, attack, and range, which are also not in the test json right now


func _on_Timeline_gui_input(event):
	if event is InputEventMouseButton:
		emit_signal("timeline_interaction", event.pressed)
