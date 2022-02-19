extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var players = [$PlayerOne, $PlayerTwo, $PlayerThree, $PlayerFour]
var turn = 0
var gamelog
var turns
var ready = false
var players_moved = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_FileDialog_file_loaded():
	gamelog = $"../FileDialog".GameLog.result
	ready = true
	turns = gamelog["GameLog"]["Main"]["Turns"]
	for i in len(players):
		players[i].instantMoveTo(turns[0]["Players"][i]["Position"])
		players[i].updateClass(turns[0]["Players"][i]["Class"].capitalize())
		players[i].visible = true
	

func nextTurn():
	if ready:
		for i in range(len(players)):
			players[i].moveTo(turns[turn]["Players"][i]["Position"])
		yield(get_tree().create_timer($TurnTimer.wait_time / 4), "timeout")
		
		for action in turns[turn]["Actions"]:
			if (action["Action"] == "attack"):
				players[action["Player"] - 1].attack(players[int(action["Target"])- 1].position) #add targeting reticles?
			elif (action["Action"] == "buy"):
				pass #do something
			elif (action["Action"] == "use"):
				pass
		
		for i in range(len(players)):
			if turns[turn]["Players"][i]["Health"] < 0:
				pass #die animation, then respawn at base as part of die animation
		turn += 1
		if turn >= len(turns):
			turn = 0
			# $TurnTimer.stop()
		
	

func _on_Timer_timeout():
	nextTurn()
