extends CanvasLayer

var tween:Tween

#NOTE: Relies on being inside the Global group of GUI to get event calls from other actors.

#Call from player to update the health
func update_health(health):
	$HBoxContainer/Health.text = str(health) + "%"
	$ProgressBar.value = health

#TODO: This needs to be completely replaced with some kind of message array.

#Display when we pick up items.
func update_pickup_box(item):
	$ItemList.add_item("You Got: " + str(item) )
	tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.tween_property($ItemList, "modulate:a", 1.0, 0.1)
	$ItemList/lifeTimer.start(2.0)

#Turn off the message box and clear it
func _on_life_timer_timeout() -> void:
	tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.tween_property($ItemList, "modulate:a", 0.0, 0.1)
	tween.tween_callback($ItemList.clear)
	
func update_weapon_bar(weapon):
	pass

#Weapons calls to update the crosshair
func update_crosshair(crosshair_texture):
	$Crosshair.texture = crosshair_texture

func update_crosshair_color(ray_collision):
	if ray_collision:
		$Crosshair.set_modulate(Color(1,0,0,1))
	else:
		$Crosshair.set_modulate(Color(1,1,1,1))
