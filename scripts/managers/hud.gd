extends CanvasLayer

#NOTE: Relies on being inside the Global group of GUI to get event calls from other actors.

#Call from player to update the health
func update_health(health):
	$HBoxContainer/Health.text = str(health) + "%"

#TODO: This needs to be completely replaced with some kind of message array.

#Display when we pick up items.
func update_pickup_box(item):
	$ItemList.add_item("You Got: " + str(item) )
	$ItemList.visible = true
	$ItemList/lifeTimer.start(2.0)

#Turn off the message box and clear it
func _on_life_timer_timeout() -> void:
	$ItemList.visible = false
	$ItemList.clear()

#Weapons calls to update the crosshair
func update_crosshair(crosshair_texture):
	$Crosshair.texture = crosshair_texture
