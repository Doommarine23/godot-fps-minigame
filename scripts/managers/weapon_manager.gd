##Originall inside player.gd. Controls which weapon resource is loaded and actually attacks with them.

extends Node

@export_subgroup("Weapons")
@export var weapons: Array[Weapon] = []

@onready var player: CharacterBody3D = $"../../../../../.."
@onready var blaster_cooldown = $"../../../../../../Cooldown"
@onready var raycast = $"../../../../RayCast"
@onready var muzzle = $"../Muzzle"
@onready var camera = $"../../../.."
@onready var crosshair: TextureRect = $"../CenterContainer/TextureRect"


var tween:Tween

var weapon: Weapon
var weapon_index := 0

var container_offset = Vector3(1.2, -1.1, -2.75)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	weapon = weapons[weapon_index] # Weapon must never be nil TODO: Add a "no weapons" weapon ala Halo.
	initiate_change_weapon(weapon_index)
	pass # Replace with function body.


#May seem unnessary but we do move the player around so it is better to be in physics
func _physics_process(delta: float) -> void:
	# Shooting
	
	action_shoot()
		
	# Weapon switching
	
	action_weapon_toggle()

# Shooting TODO: Split into a weapon manager script on the Container node.

func action_shoot():
	
	if Input.is_action_pressed("shoot"):
	
		if !blaster_cooldown.is_stopped(): return # Cooldown for shooting
		
		Audio.play(weapon.sound_shoot)
		
		self.position.z += 0.25 # Knockback of weapon visual
		camera.rotation.x += 0.025 # Knockback of camera
		player.movement_velocity += Vector3(0, 0, weapon.knockback) # Knockback
		
		# Set muzzle flash position, play animation
		
		muzzle.play("default")
		
		muzzle.rotation_degrees.z = randf_range(-45, 45)
		muzzle.scale = Vector3.ONE * randf_range(0.40, 0.75)
		muzzle.position = self.position - weapon.muzzle_position
		
		blaster_cooldown.start(weapon.cooldown)
		
		# Shoot the weapon, amount based on shot count
		
		for n in weapon.shot_count:
		
			raycast.target_position.x = randf_range(-weapon.spread, weapon.spread)
			raycast.target_position.y = randf_range(-weapon.spread, weapon.spread)
			
			raycast.force_raycast_update()
			
			if !raycast.is_colliding(): continue # Don't create impact when raycast didn't hit
			
			var collider = raycast.get_collider()
			
			# Hitting an enemy
			
			if collider.has_method("damage"):
				collider.damage(weapon.damage)
			
			# Creating an impact animation
			
			var impact = preload("res://scenes/objects/actors/fx/impact.tscn")
			var impact_instance = impact.instantiate()
			
			impact_instance.play("shot")
			
			get_tree().root.add_child(impact_instance)
			
			impact_instance.position = raycast.get_collision_point() + (raycast.get_collision_normal() / 10)
			impact_instance.look_at(camera.global_transform.origin, Vector3.UP, true) 

# Toggle between available weapons (listed in 'weapons')

#TODO: Probably replace with an addon for a weapon wheel or something better.
func action_weapon_toggle():
	
	if Input.is_action_just_pressed("weapon_toggle"):
		
		weapon_index = wrap(weapon_index + 1, 0, weapons.size())
		initiate_change_weapon(weapon_index)
		
		Audio.play("sounds/actors/player/weapons/weapon_change.ogg")
	
	if Input.is_action_just_pressed("weapon_toggle_back"):
		
		weapon_index = wrap(weapon_index - 1, 0, weapons.size())
		initiate_change_weapon(weapon_index)
		
		Audio.play("sounds/actors/player/weapons/weapon_change.ogg")

# Initiates the weapon changing animation (tween)

func initiate_change_weapon(index):
	
	weapon_index = index
	
	tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.tween_property(self, "position", container_offset - Vector3(0, 1, 0), 0.1)
	tween.tween_callback(change_weapon) # Changes the model

# Switches the weapon model (off-screen)

func change_weapon():
	
	weapon = weapons[weapon_index]

	# Step 1. Remove previous weapon model(s) from container
	
	for n in self.get_children():
		self.remove_child(n)
	
	# Step 2. Place new weapon model in container
	
	var weapon_model = weapon.model.instantiate()
	self.add_child(weapon_model)
	
	weapon_model.position = weapon.position
	weapon_model.rotation_degrees = weapon.rotation
	
	# Step 3. Set model to only render on layer 2 (the weapon camera)
	
	for child in weapon_model.find_children("*", "MeshInstance3D"):
		child.layers = 2
		
	# Set weapon data
	
	raycast.target_position = Vector3(0, 0, -1) * weapon.max_distance
	crosshair.texture = weapon.crosshair
