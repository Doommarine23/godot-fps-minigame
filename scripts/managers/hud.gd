extends CanvasLayer


func _on_health_updated(health):
	$HBoxContainer/Health.text = str(health) + "%"
