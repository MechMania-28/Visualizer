extends PanelContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func update_health(new_health):
	for i in $PlayerContainer/HeartContainer.get_child_count():
		$PlayerContainer/HeartContainer.get_child(i).visible = new_health > i

func update_gold(value):
	$PlayerContainer/HBoxContainer/PlayerInfo/IconStats/Coins.text = str(value)

func update_attack(value):
	$PlayerContainer/HBoxContainer/PlayerInfo/IconStats/Attack.text = str(value)
	
func update_range(value):
	$PlayerContainer/HBoxContainer/PlayerInfo/IconStats/Range.text = str(value)
	
func update_speed(value):
	$PlayerContainer/HBoxContainer/PlayerInfo/IconStats/Speed.text = str(value)

func update_score(value):
	$PlayerContainer/HBoxContainer/PlayerInfo/Score.text = "Score: " + str(value)

func update_item(value):
	$PlayerContainer/HBoxContainer/PlayerInfo/Item.text = "Item: " + str(value)

func set_name(value):
	$PlayerContainer/NameLabel.text = "Name: " + str(value)

func update_class(new_class):
	#$PlayerContainer/HBoxContainer/P1ClassSprite.texture = class_texture
	pass
