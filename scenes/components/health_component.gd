extends Node
class_name HealthComponent

@export var max_health: int = 100

var health: int

func _ready() -> void:
	health = max_health
	
#func modify_health(value : int, is_damage : bool):
	##Could I somehow do this on the input field? Either way, ensure health value is always a positive.
	#abs(value)
	#
	#if is_damage:
		#health -= value
	#else:
		#health += value
	#
	#if health > max_health:
		#health = max_health
	#
	#get_tree().call_group("GUI", "update_health", health)

func give_health(value : int):
	health += value
	if health > max_health:
		health = max_health
	
	if get_parent().is_in_group("player"):
		get_tree().call_group("GUI", "update_health", health)

func receive_damage(value : int):
	health -= value
	print("Health Remaining: " + str(health))
	
	print(str(get_parent()))
	
	if get_parent().is_in_group("player"):
		get_tree().call_group("GUI", "update_health", health)
	
	if health <= 0 && !get_parent().is_in_group("player"):
		get_parent().queue_free()
	elif health <= 0 && get_parent().is_in_group("player"):
		get_tree().reload_current_scene()
