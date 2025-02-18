class_name Projectile
extends RigidBody3D

@export var speed:float = -20.0 #Negative is forwards
@export var soundFX: AudioStreamPlayer3D

#We multiply by transform basis so projectile goes forwards no matter direction
#Thanks to athousandships on Godot forums. Credit in readme.md

func _physics_process(delta: float) -> void:
	move_and_collide( (global_transform.basis * Vector3(0,0,speed)) * delta)

func _on_life_timeout() -> void:
	explosion()
	
#TODO: Explosion sphere that does damage based on your distance from center.
#TODO: Define a set of explosion / impact sounds later to make this more dynamic / scalable.
func explosion():
	#TODO: This should spawn an explosion entity sphere that is set inside the game world, and this sound plays inside it instead.
	#soundFX.set_stream( load("sounds/actors/fx/explosionCrunch_000.ogg") )
	#soundFX.play()
	queue_free()

func _on_body_entered(_body: Node) -> void:
	explosion()
