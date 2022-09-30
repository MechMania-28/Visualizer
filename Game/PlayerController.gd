extends Node2D

signal forced_pause(paused)

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var players = [$PlayerOne, $PlayerTwo, $PlayerThree, $PlayerFour]
onready var UI = $"../UI"
onready var total_turn_time = $TurnTimer.wait_time
onready var move_time = total_turn_time / 8
onready var attack_time = total_turn_time / 8
onready var use_time = total_turn_time / 12
# ["Blue ", "Green ", "Red ", "Purple "]
var turn = 0
var gamelog
var turns
var ready = false
var timeline_clicked = false
var class_healths = {"WIZARD" : 6, "KNIGHT" : 9, "ARCHER" : 3}
var colors = ["R", "B", "P", "G"]
onready var inactive_shader = preload("res://Assets/Disconnected_Shader.tres")

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(4):
		players[i].my_color = colors[i]
		players[i].move_time_unit = move_time
	
func reset():
	UI.update_turn_num(0)
	jumpToTurn(0)
	nextTurn()

func nextTurn():
	turn += 1
	UI.update_turn_num(turn)
	$TurnTimer.start(total_turn_time)
	if ready:
		for i in range(len(players)):
			if (turns[turn]["player_states"][i]["item_in_use"] == "NONE"):
				UI.update_active_item(i, "NONE")
			UI.update_turns_left(i, turns[turn]["player_states"][i]["effect_timer"])
			if (!turns[turn]["player_states"][i]["isActive"]):
				players[i].material = inactive_shader
			if (turns[turn]["player_states"][i]["shielded"]):
				players[i].shielded(turns[turn]["player_states"][i]["shielded"])
		
		#dying movement
		if turn > 0:
			for i in range(len(players)):
				if turns[turn-1]["player_states"][i]["health"] <= 0:
					players[i].instantMoveTo(turns[0]["player_states"][i]["position"])
					UI.update_health(i, class_healths[turns[turn-1]["player_states"][i]["class"]])
		
		var used = false
		for action in turns[turn]["use_actions"]:
			if (action != null and action["use"] and action["isValid"] and turns[turn]["player_states"][action["executor"]]["item"] == "NONE"):
				UI.update_item(action["executor"], "NONE")
				
				UI.update_active_item(action["executor"], turns[turn]["player_states"][action["executor"]]["item_in_use"])
				UI.update_turns_left(action["executor"], turns[turn]["player_states"][action["executor"]]["effect_timer"])
				
				if (turns[turn]["player_states"][action["executor"]]["shielded"]):
					players[action["executor"]].shielded(true)
					UI.update_shielded(action["executor"], true)
				players[action["executor"]].updateClass(turns[turn]["player_states"][action["executor"]]["class"][0])
				players[action["executor"]].use()
				used = true
		UI.update_player_stats(turns[turn]["player_states"])
		
		if (used):
			yield(get_tree().create_timer(use_time*1.5), "timeout")
		
		for i in range(len(players)):
			# if (turns[turn]["move_actions"][i]["destination"]["x"] != -1):
			players[i].moveTo(turns[turn]["player_states"][i]["position"])
		yield(get_tree().create_timer(move_time), "timeout")
		
		for action in turns[turn]["attack_actions"]:
			if (action != null and action["executor"] != action["target"] and action["isValid"]):
				if (action["nullified"]):
					players[action["target"]].shielded(false)
					UI.update_shielded(action["target"], false)
				else:
					players[action["target"]].hurt()
					UI.subtract_health(action["target"], action["damage"])
				players[action["executor"]].attack(players[int(action["target"])].position)
				yield(get_tree().create_timer(attack_time), "timeout")
				#add targeting reticles
		
		var bought = false
		for action in turns[turn]["buy_actions"]:
			if (action != null and action["isValid"] and action["item"] != "NONE" and turns[turn]["player_states"][action["executor"]]["item"] != "NONE"):
				players[action["executor"]].buy()
				UI.update_item(action["executor"], action["item"])
				#UI.update_item(action["executor"], turns[turn]["player_states"][action["executor"]]["item"])
				bought = true
		
				
		UI.end_turn_update_player_stats(turns[turn]["player_states"])
		
		if (bought):
			yield(get_tree().create_timer(use_time), "timeout")
		
		var healing = false
		for i in range(4):
			if (turns[turn]["player_states"][i]["position"]["x"] == turns[0]["player_states"][i]["position"]["x"] and 
				turns[turn]["player_states"][i]["position"]["y"] == turns[0]["player_states"][i]["position"]["y"]):
				players[i].healing()
				UI.update_health(i, turns[turn]["player_states"][i]["health"])
				healing = true
		if (healing):
			yield(get_tree().create_timer(use_time/2), "timeout")
		
		var die = false
		for i in range(len(players)):
			UI.update_item(i, turns[turn]["player_states"][i]["item"])
			#print(turns[turn]["player_states"][i]["health"])
			if turns[turn]["player_states"][i]["health"] <= 0:
				players[i].die()
				die = true
		if (die):
			yield(get_tree().create_timer(use_time/2), "timeout")
		
		$TurnTimer.start(.5)
		# Check if game is over
		if turn >= len(turns) - 1:
			#turn = 0
			UI.force_pause(true)
			$TurnTimer.set_paused(true)
		


func jumpToTurn(new_turn):
	if ready:
		turn = new_turn
		UI.update_turn_num(turn)
		for i in range(len(players)):
			UI.update_turns_left(i, turns[turn]["player_states"][i]["effect_timer"])
			if (!turns[turn]["player_states"][i]["isActive"]):
				players[i].material = inactive_shader
			else:
				players[i].material = null
		
			UI.update_item(i, turns[turn]["player_states"][i]["item"])
			UI.update_active_item(i, turns[turn]["player_states"][i]["item_in_use"])
			UI.update_turns_left(i, turns[turn]["player_states"][i]["effect_timer"])
				
			UI.update_player_stats(turns[turn]["player_states"])
			
			# TODO fix
			players[i].shielded(turns[turn]["player_states"][i]["shielded"])
			UI.update_shielded(i, turns[turn]["player_states"][i]["shielded"])
			for action in turns[turn]["attack_actions"]:
				if (action != null and action["executor"] != action["target"] and action["isValid"]):
					if (action["nullified"]):
						players[action["target"]].shielded(false)
						UI.update_shielded(action["target"], false)
		
			players[i].updateClass(turns[turn]["player_states"][i]["class"][0])
		
			players[i].instantMoveTo(turns[turn]["player_states"][i]["position"])
		

			if (turns[turn]["player_states"][i]["position"]["x"] == turns[0]["player_states"][i]["position"]["x"] and 
				turns[turn]["player_states"][i]["position"]["y"] == turns[0]["player_states"][i]["position"]["y"]):
				players[i].healing()
				
			UI.end_turn_update_player_stats(turns[turn]["player_states"])

			if turns[turn]["player_states"][i]["health"] <= 0:
				players[i].die()
		
		if new_turn >= len(turns)-1:
			UI.force_pause(true)
			$TurnTimer.set_paused(true)

# Handling the timer
func _on_Timer_timeout():
	if (turn >= len(turns) - 1):
		reset()
	else:
		nextTurn()

func _on_UI_pause_toggled(playing):
	if playing:
		_on_Timer_timeout()
		$TurnTimer.set_paused(false)
	else:
		$TurnTimer.set_paused(true)

func _on_UI_timeline_changed(value):
	if (timeline_clicked):
		jumpToTurn(value)

func _on_UI_timeline_interaction(clicked):
	timeline_clicked = clicked
	if clicked:
		UI.force_pause(true)


func _on_FileSelect_file_loaded(new_gamelog, names):
	turn = 0
	gamelog = new_gamelog
	ready = true
	#turns = gamelog["GameLog"]["Main"]["Turns"]
	turns = gamelog
	for i in len(players):
		#players[i].instantMoveTo(turns[0]["Players"][i]["Position"])
		players[i].instantMoveTo(turns[0]["player_states"][i]["position"])
		players[i].updateClass(turns[0]["player_states"][i]["class"][0].capitalize())
		#players[i].move_time_unit = move_time
		#players[i].my_color = "Red" #TEST
		players[i].visible = true
	UI.update_player_stats(turns[0]["player_states"])
	UI.end_turn_update_player_stats(turns[0]["player_states"])
	UI.update_names(names)
	UI.change_max_turns(len(turns))
	$Logo.visible = false
	$TurnTimer.start()
	$TurnTimer.set_paused(false)
	nextTurn()
