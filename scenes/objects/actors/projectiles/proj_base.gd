class_name Projectile
extends RigidBody3D

@export var speed:float = -20.0 #Negative is forwards

#We multiply by transform basis so projectile goes forwards no matter direction
#Thanks to athousandships on Godot forums. Credit in readme.md

func _physics_process(delta: float) -> void:
	move_and_collide( (global_transform.basis * Vector3(0,0,speed)) * delta)

func _on_life_timeout() -> void:
	explosion()
	
#TODO: Explosion sphere that does damage based on your distance from center.
func explosion():
	Audio.play("sounds/actors/fx/explosionCrunch_000.ogg")
	queue_free()

func _on_body_entered(body: Node) -> void:
	explosion()
