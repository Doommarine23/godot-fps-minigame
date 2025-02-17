extends Area3D
class_name SentryAIComponent

var has_target = null
var time: float = 0.0
var target_position: Vector3
var active_target

#TODO: gun component
@export var shot_damage: float = 5
@export var gun_cooldown: Timer
@export var parent_npc: Node3D
@export var raycast: RayCast3D
@onready var muzzle_a = $"../MuzzleA"
@onready var muzzle_b = $"../MuzzleB"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	target_position = parent_npc.position

func _process(delta: float) -> void:
	if has_target != null:
		parent_npc.look_at(has_target.position + Vector3(0, 0.5, 0), Vector3.UP, true)
		active_target = has_target
	else:
		active_target = null
	
	target_position.y += (cos(time * 5) * 1) * delta  # Sine movement (up and down)
	time += delta
	parent_npc.position = target_position

func _on_body_entered(body: Node3D) -> void:
	has_target = body

func _on_body_exited(body: Node3D) -> void:
	has_target = null

func _on_timer_timeout() -> void:
	var collider = raycast.get_collider()
	if active_target:
		if raycast.is_colliding():
			if collider is HitBoxComponent:
				collider.give_damage(shot_damage)	
				muzzle_a.frame = 0
				muzzle_a.play("default")
				muzzle_a.rotation_degrees.z = randf_range(-45, 45)

				muzzle_b.frame = 0
				muzzle_b.play("default")
				muzzle_b.rotation_degrees.z = randf_range(-45, 45)

				Audio.play("sounds/actors/mobs/enemy_attack.ogg")
