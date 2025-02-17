extends Area3D
class_name HitBoxComponent

@export var health_component : HealthComponent

#signal send_damage

func give_damage(value):
	if health_component:
		health_component.receive_damage(value)
