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
onready var player_panels = [p1panel, p3panel, p4panel, p2panel]

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

func force_pause(paused):
	$UI/HBoxContainer/TimeControls/PlayButton.pressed = not paused


func update_turn_num(turn):
	$UI/HBoxContainer/TimeControls/Panel/VBoxContainer/Label2.text = str(turn)
	$UI/HBoxContainer/TimeControls/Timeline.value = turn


func update_health(player, new_health):
	player_panels[player].update_health(new_health)

func subtract_health(player, health_diff):
	player_panels[player].subtract_health(health_diff)

func update_player_stats(stat_array):
	for i in range(4):
		#player_panels[i].update_health(stat_array[i]["health"])
		#player_panels[i].update_score(stat_array[i]["score"])
		#player_panels[i].update_gold(stat_array[i]["gold"])
		#var item_formatted = stat_array[i]["item"].replacen("_", " ").capitalize()
		#player_panels[i].update_item(item_formatted)
		player_panels[i].update_speed(stat_array[i]["stat_set"]["speed"])
		player_panels[i].update_attack(stat_array[i]["stat_set"]["damage"])
		player_panels[i].update_range(stat_array[i]["stat_set"]["range"])
		# update speed, attack, and range, which are also not in the test json right now
func end_turn_update_player_stats(stat_array):
	for i in range(4):
		player_panels[i].update_health(stat_array[i]["health"])
		player_panels[i].update_score(stat_array[i]["score"])
		player_panels[i].update_gold(stat_array[i]["gold"])
func update_item(player, item):
	var item_formatted = item.replacen("_", " ").capitalize()
	player_panels[player].update_item(item_formatted)
func update_active_item(player, item):
	var item_formatted = item.replacen("_", " ").capitalize()
	player_panels[player].update_active_item(item_formatted)
func update_turns_left(player, value):
	player_panels[player].update_turns_left(value)
func update_shielded(player, value):
	player_panels[player].update_shielded(value)
func _on_Timeline_gui_input(event):
	if event is InputEventMouseButton:
		emit_signal("timeline_interaction", event.pressed)
func update_names(name_array):
	for i in range(4):
		player_panels[i].set_name(name_array[i])
func change_max_turns(turns):
	$UI/HBoxContainer/TimeControls/Timeline.max_value = turns - 1
