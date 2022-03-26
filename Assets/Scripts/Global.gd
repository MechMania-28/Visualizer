extends Node

const GAMELOG_ = "GameLog"
const GAMELOG_MAIN = "Main"
const GAMELOG_INFO = "Info"
const GAMELOG_TURNS = "Turns"
const GAMELOG_TURNNUM = "TurnNum"
const GAMELOG_PLAYERS = "Players"

const GAMELOG_PLAYER_ID = "Player"
const GAMELOG_PLAYER_CLASS = "Class"
const GAMELOG_PLAYER_BUFFS = "StatBuffs"
const GAMELOG_PLAYER_ITEM = "Item"
const GAMELOG_PLAYER_POS = "Position"
const GAMELOG_PLAYER_HP = "Health"
const GAMELOG_PLAYER_GOLD = "Gold"

const GAMELOG_ACTIONS = "Actions"
const GAMELOG_ACTION_ID = "Player"
const GAMELOG_ACTION_TARGET = "Target"
const GAMELOG_ACTION_ACTION = "Action"

signal gamelog_verification_start
signal gamelog_verification_complete
signal gamelog_verification_failed
signal progress_text_changed
signal progress_changed

var GameLog : Dictionary
var gamelog_states : Array
var progress : float = 0 setget _set_progress
var max_progress : float
var progress_text : String = "" setget _set_progress_text

var current_turn : int # Current turn in play
var player_count : int # Number of players in game


func _ready():
	set_process(false)


# Starts gamelog verification process
func verify_GameLog(_gamelog):
	
	if !_valid_keys(_gamelog): 
		emit_signal("gamelog_verification_failed")
		return
	GameLog = _gamelog
	gamelog_states = GameLog[GAMELOG_][GAMELOG_MAIN][GAMELOG_TURNS].duplicate(false)
	progress = 0
	max_progress = gamelog_states.size() - 1
	set_process(true)
	emit_signal("gamelog_verification_start")


# Verification iteration
func _process(_delta):
	
	# Adjustable # of turns to verify per iteration
	for _i in range(1):
		
		if gamelog_states.empty():
			_set_progress(max_progress)
			_set_progress_text("Verification complete!")
			emit_signal("gamelog_verification_complete")
			set_process(false)
			return
		
		var state = gamelog_states.pop_front()
		if !_valid_state(state):
			emit_signal("gamelog_verification_failed")
			set_process(false)
			return
		
		_set_progress(progress + 1)
		_set_progress_text("Verified %s/%s" % [progress, max_progress])
		#_set_progress_text(progress_text)
		
	

# Verifies that Main, Info, and Turns exist and are correct
func _valid_keys(gamelog) -> bool:
	if gamelog == null or !(gamelog is Dictionary): 
		_set_progress_text("Invalid file")
		return false
	if !gamelog.has(GAMELOG_): 
		_set_progress_text("Invalid file, missing \"%s\"" % GAMELOG_)
		return false
	if !gamelog[GAMELOG_].has(GAMELOG_MAIN): 
		_set_progress_text("Invalid file, missing \"%s\"" % GAMELOG_MAIN)
		return false 
	if !gamelog[GAMELOG_][GAMELOG_MAIN].has(GAMELOG_INFO):
		_set_progress_text("Invalid file, missing \"%s\"" % GAMELOG_INFO) #TODO: Verify GAMELOG_INFO
		return false
	if !gamelog[GAMELOG_][GAMELOG_MAIN].has(GAMELOG_TURNS): 
		_set_progress_text("Invalid file, missing \"%s\"" % GAMELOG_TURNS)
		return false
	player_count = gamelog[GAMELOG_][GAMELOG_MAIN][GAMELOG_INFO].size() # Set player count
	# player_count = gamelog[GAMELOG_][GAMELOG_MAIN][GAMELOG_INFO][GAMELOG_PLAYER_COUNT] would be better
	# Current method may not work in the future
	return true

# verifies each turn is correct
func _valid_state(state: Dictionary) -> bool:
	return _valid_TurnNum(state) and _valid_Players(state) and _valid_Actions(state)

# Verifies TurnNum
var true_turnNum : int = 1
func _valid_TurnNum(state: Dictionary) -> bool:
	if !state.has(GAMELOG_TURNNUM): 
		_set_progress_text("Invalid turn, missing key \"%s\" (%d)" % [GAMELOG_TURNNUM, true_turnNum])
		return false
	if !(state[GAMELOG_TURNNUM] is float) or !_is_integer(state[GAMELOG_TURNNUM]) or state[GAMELOG_TURNNUM] < 0:
		_set_progress_text("Invalid \"%s\", (%s) is !(a positive integer" % [GAMELOG_TURNNUM,state[GAMELOG_TURNNUM]])
		return false
	if int(state[GAMELOG_TURNNUM]) != true_turnNum:
		_set_progress_text("Out of order \"%s\", (%s) should be (%d)" % [GAMELOG_TURNNUM, state[GAMELOG_TURNNUM], true_turnNum])
		return false
	true_turnNum+=1
	return true

# Verifies Players info
func _valid_Players(state: Dictionary) -> bool:
	if !state.has(GAMELOG_PLAYERS):
		_set_progress_text("Invalid turn, missing key \"%s\"" % GAMELOG_PLAYERS)
		return false
	var players = state[GAMELOG_PLAYERS]
	if !players is Array:
		_set_progress_text("Invalid \"%s\" in turn %d, object is !(an array" % [GAMELOG_PLAYERS, true_turnNum])
		return false
	if players.size() != player_count:
		_set_progress_text("Invalid \"%s\" in turn %d, %d/%d players found" % [GAMELOG_PLAYERS, true_turnNum, players.size(), player_count])
		return false
	
	for i in range(players.size()):
		var player = players[i]
		if !(player is Dictionary):
			_set_progress_text("Invalid \"%s\" in turn %s, object %d is !(a dictionary" % [GAMELOG_PLAYERS, true_turnNum, i])
			return false
		
		if !player.has(GAMELOG_PLAYER_ID):
			_set_progress_text("Invalid \"%s\" in turn %s, object %d is missing key \"%s\"" % [GAMELOG_PLAYERS, true_turnNum, GAMELOG_PLAYER_ID])
			return false
		var id = player[GAMELOG_PLAYER_ID]
		if  !(id is float) or !_is_integer(id) or id < 0 or id > player_count:
			_set_progress_text("Invalid \"%s\" in turn %s, object %d contains invalid data for \"%s\"" % [GAMELOG_PLAYERS, true_turnNum, GAMELOG_PLAYER_ID])
			return false
		
		if !player.has(GAMELOG_PLAYER_CLASS):
			_set_progress_text("Invalid \"%s\" in turn %s, object %d is missing key \"%s\"" % [GAMELOG_PLAYERS, true_turnNum, GAMELOG_PLAYER_CLASS])
			return false
		if !(player[GAMELOG_PLAYER_CLASS] is String):
			_set_progress_text("Invalid \"%s\" in turn %s, object %d contains invalid data for \"%s\"" % [GAMELOG_PLAYERS, true_turnNum, GAMELOG_PLAYER_CLASS])
			return false
		
		if !player.has(GAMELOG_PLAYER_BUFFS):
			_set_progress_text("Invalid \"%s\" in turn %s, object %d is missing key \"%s\"" % [GAMELOG_PLAYERS, true_turnNum, GAMELOG_PLAYER_BUFFS])
			return false
		if !(player[GAMELOG_PLAYER_BUFFS] is Array): # TODO: verify individual buffs
			_set_progress_text("Invalid \"%s\" in turn %s, object %d contains invalid data for \"%s\"" % [GAMELOG_PLAYERS, true_turnNum, GAMELOG_PLAYER_BUFFS])
			return false
		
		if !player.has(GAMELOG_PLAYER_ITEM):
			_set_progress_text("Invalid \"%s\" in turn %s, object %d is missing key \"%s\"" % [GAMELOG_PLAYERS, true_turnNum, GAMELOG_PLAYER_ITEM])
			return false
		if !(player[GAMELOG_PLAYER_ITEM] is String):
			_set_progress_text("Invalid \"%s\" in turn %s, object %d contains invalid data for \"%s\"" % [GAMELOG_PLAYERS, true_turnNum, GAMELOG_PLAYER_ITEM])
			return false
		
		if !player.has(GAMELOG_PLAYER_POS):
			_set_progress_text("Invalid \"%s\" in turn %s, object %d is missing key \"%s\"" % [GAMELOG_PLAYERS, true_turnNum, GAMELOG_PLAYER_POS])
			return false
		var pos = player[GAMELOG_PLAYER_POS]
		if !(pos is Array) or pos.size() != 2:
			_set_progress_text("Invalid \"%s\" in turn %s, object %d contains invalid data for \"%s\"" % [GAMELOG_PLAYERS, true_turnNum, GAMELOG_PLAYER_POS])
			return false
		for j in range(2):
			if !(pos[j] is float) or !_is_integer(pos[j]):
				_set_progress_text("Invalid \"%s\" in turn %s, object %d contains invalid data for \"%s\"" % [GAMELOG_PLAYERS, true_turnNum, GAMELOG_PLAYER_POS])
				return false
		
		if !player.has(GAMELOG_PLAYER_HP):
			_set_progress_text("Invalid \"%s\" in turn %s, object %d is missing key \"%s\"" % [GAMELOG_PLAYERS, true_turnNum, GAMELOG_PLAYER_HP])
			return false
		var hp = player[GAMELOG_PLAYER_HP]
		if !(hp is float) or !_is_integer(hp):
			_set_progress_text("Invalid \"%s\" in turn %s, object %d contains invalid data for \"%s\"" % [GAMELOG_PLAYERS, true_turnNum, GAMELOG_PLAYER_HP])
			return false
		
		if !player.has(GAMELOG_PLAYER_GOLD):
			_set_progress_text("Invalid \"%s\" in turn %s, object %d is missing key \"%s\"" % [GAMELOG_PLAYERS, true_turnNum, GAMELOG_PLAYER_GOLD])
			return false
		var gold = player[GAMELOG_PLAYER_GOLD]
		if !(gold is float) or !_is_integer(gold):
			_set_progress_text("Invalid \"%s\" in turn %s, object %d contains invalid data for \"%s\"" % [GAMELOG_PLAYERS, true_turnNum, GAMELOG_PLAYER_HP])
			return false
		
	
	return true


# Verifies Actions
func _valid_Actions(state: Dictionary) -> bool:
	if !state.has(GAMELOG_ACTIONS):
		_set_progress_text("Invalid file, missing \"%s\"" % GAMELOG_ACTIONS)
		return false
	
	var actions = state[GAMELOG_ACTIONS]
	if !(actions is Array):
		_set_progress_text("Invalid file, \"%s\" is not an array" % GAMELOG_ACTIONS)
		return false
	
	for i in range(actions.size()):
		var action = actions[i]
		if !(action is Dictionary):
			_set_progress_text("Invalid action in turn %s, action %d is not a dictionary" % [ true_turnNum, i])
			return false
		
		if !action.has(GAMELOG_ACTION_ID):
			_set_progress_text("Invalid action in turn %s, action %d is missing \"%s\"" % [ true_turnNum, i, GAMELOG_ACTION_ID])
			return false
		if !(action[GAMELOG_ACTION_ID] is float) or !_is_integer(action[GAMELOG_ACTION_ID]):
			_set_progress_text("Invalid action in turn %s, action %d contains invalid \"%s\"" % [ true_turnNum, i, GAMELOG_ACTION_ID])
			return false
		
		if !action.has(GAMELOG_ACTION_ACTION):
			_set_progress_text("Invalid action in turn %s, action %d is missing \"%s\"" % [ true_turnNum, i, GAMELOG_ACTION_ACTION])
			return false
		if !(action[GAMELOG_ACTION_ACTION] is String):
			_set_progress_text("Invalid action in turn %s, action %d contains invalid \"%s\"" % [ true_turnNum, i, GAMELOG_ACTION_ACTION])
			return false
		
		if !action.has(GAMELOG_ACTION_TARGET):
			_set_progress_text("Invalid action in turn %s, action %d is missing \"%s\"" % [ true_turnNum, i, GAMELOG_ACTION_TARGET])
			return false
		if !(action[GAMELOG_ACTION_TARGET] is String):
			_set_progress_text("Invalid action in turn %s, action %d contains invalid \"%s\"" % [ true_turnNum, i, GAMELOG_ACTION_TARGET])
			return false
		
	
	return true


func _set_progress_text(new : String):
	progress_text = new
	#print(progress_text)
	emit_signal("progress_text_changed", new)

func _set_progress(new: float):
	progress = new
	emit_signal("progress_changed", new / max_progress)

func _is_integer(x : float):
	return fmod(x, 1.0) == 0
