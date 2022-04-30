extends Node2D

signal forced_pause(paused)

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var players = [$PlayerOne, $PlayerTwo, $PlayerThree, $PlayerFour]
onready var UI = $"../UI"
var player_colors = ["Blue ", "Green ", "Red ", "Purple "]
var turn = 0
var gamelog
var turns
var ready = false
var timeline_clicked = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_FileDialog_file_loaded(new_gamelog):
	gamelog = new_gamelog
	ready = true
	#turns = gamelog["GameLog"]["Main"]["Turns"]
	turns = gamelog
	turn = 0
	for i in len(players):
		players[i].my_color = player_colors[i]
		#players[i].instantMoveTo(turns[0]["Players"][i]["Position"])
		players[i].instantMoveTo(turns[0]["player_states"][i]["position"])
		players[i].updateClass(turns[0]["player_states"][i]["class"].capitalize())
		players[i].visible = true
	UI.update_player_stats(turns[0]["player_states"])
	$TurnTimer.start()
	nextTurn()
	
func reset():
	UI.update_turn_num(0)
	jumpToTurn(0)

func nextTurn():
	turn += 1
	UI.update_turn_num(turn)
	print(turn)
	if ready:
		# if they died the previous turn, move them to the base for the beginning of this turn
		if turn > 0:
			for i in range(len(players)):
				if turns[turn-1]["player_states"][i]["health"] <= 0:
					players[i].instantMoveTo(turns[0]["player_states"][i]["position"])
		
		# Moving correctly
		for i in range(len(players)):
			players[i].moveTo(turns[turn]["player_states"][i]["position"])
		
		yield(get_tree().create_timer($TurnTimer.wait_time / 4), "timeout")
		# Do actions
		
		for action in turns[turn]["attack_actions"]:
			if (action != null):
				players[action["executor"]].attack(players[int(action["target"])- 1].position)
				players[action["target"]].hurt()
				#currently this updates the effect of all attacks as if only the first attack did all
				#of the damage. json should be updated to prevent this
				UI.update_health(action["target"], turns[turn]["player_states"][action["target"]]["health"])
				yield(get_tree().create_timer($TurnTimer.wait_time / 10), "timeout")
				#add targeting reticles
		for action in turns[turn]["use_actions"]:
			if (action != null):
				#players[action["executor"]].attack(players[int(action["target"])- 1].position)
				pass
		for action in turns[turn]["buy_actions"]:
			if (action != null):
				#players[action["executor"]].attack(players[int(action["target"])- 1].position)
				pass
		
		UI.update_player_stats(turns[turn]["player_states"])
		
		for i in range(len(players)):
			if turns[turn]["player_states"][i]["health"] < 0:
				pass #die sprite
		
		# Check if game is over
		if turn >= len(turns) - 1:
			#turn = 0
			$TurnTimer.stop()
			UI.force_pause(true)


func jumpToTurn(new_turn):
	if ready:
		turn = new_turn
		UI.update_turn_num(new_turn)
		var new_turn_json = turns[new_turn]
		for i in range(len(players)):
			players[i].instantMoveTo(new_turn_json["player_states"][i]["position"])
		for action in new_turn_json["attack_actions"]:
			if (action != null):
				players[action["executor"]].attack(players[int(action["target"])- 1].position)
				#add targeting reticles
		for action in new_turn_json["use_actions"]:
			if (action != null):
				#players[action["executor"]].attack(players[int(action["target"])- 1].position)
				pass
		for action in new_turn_json["buy_actions"]:
			if (action != null):
				#players[action["executor"]].attack(players[int(action["target"])- 1].position)
				pass
		
		# emit signal that packages all health, gold, points, etc?
		UI.update_player_stats(new_turn_json["player_states"])
		
		for i in range(len(players)):
			if new_turn_json["player_states"][i]["health"] < 0:
				pass #die sprite
		
		if new_turn >= len(turns)-1:
			UI.force_pause(true)
			$TurnTimer.stop()

# Handling the timer
func _on_Timer_timeout():
	if (turn >= len(turns) - 1):
		reset()
	else:
		nextTurn()

func _on_UI_pause_toggled(playing):
	if playing:
		_on_Timer_timeout()
		$TurnTimer.start()
		print("timer starting")
	else:
		$TurnTimer.stop()
		print("timer stopping")

func _on_UI_timeline_changed(value):
	if (timeline_clicked):
		jumpToTurn(value)

func _on_UI_timeline_interaction(clicked):
	timeline_clicked = clicked
	if clicked:
		$TurnTimer.stop()
	else:
		$TurnTimer.start()
