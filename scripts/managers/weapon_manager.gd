##Originally inside player.gd. Controls which weapon resource is loaded and actually attacks with them.

extends Node3D

@onready var player: CharacterBody3D = $"../../../../../.."
@onready var blaster_cooldown: Timer = $"../../../../../../Cooldown"
@onready var raycast: RayCast3D = $"../../../../RayCast"
@onready var secondary_ray: RayCast3D = $"../../../../Secondary_Attack_Ray"
@onready var projectile_ray: RayCast3D = $"../../../../Projectile_Ray"

@onready var muzzle = $"../Muzzle"
@onready var camera = $"../../../.."

@export_subgroup("Weapons")
@export var weapons: Array[Weapon] = []

var weapon_model = null
var tween:Tween
var weapon: Weapon
var weapon_index := 0
var is_scoped: bool = false
var container_offset = Vector3(1.2, -1.1, -2.75)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	weapon = weapons[weapon_index] # Weapon must never be nil TODO: Add a "no weapons" weapon ala Halo.
	initiate_change_weapon(weapon_index)

#May seem unnessary but we do move the player around so it is better to be in physics
func _physics_process(delta: float) -> void:
	# Shooting
	action_shoot()
	action_shoot_secondary()
	action_scope(false)
	# Weapon switching
	action_weapon_toggle()

func fire_projectile():
	var proj
	match weapon.primary_projectile:
		"proj_rocket":
			proj = weapon.projectile.instantiate()
			print("Weapon Model: " + str(weapon_model))
			#for child in weapon_model.find_children("*", "RayCast3D"):
				#print("child: " + str(child))
				#proj.transform = child.global_transform
				#proj.position = child.global_position# * player.global_position
				#proj.transform.basis = child.global_transform.basis#* player.global_transform.basis
			
			#TODO: Follow Chaff Games' guide on raycast so they come from center of screen.
			proj.position = projectile_ray.global_position
			proj.transform.basis = projectile_ray.global_transform.basis
			#proj.position.z -= 1
			#proj.position.x = randf_range(-weapon.spread, weapon.spread)
			#proj.position.y = randf_range(-weapon.spread, weapon.spread)
			get_tree().root.add_child(proj)
		
		"proj_grenade":
			print("Two are better than one!")

# Shooting
func action_shoot():
	
	if Input.is_action_pressed("shoot"):
		if !blaster_cooldown.is_stopped(): return # Cooldown for shooting
		
		Audio.play(weapon.sound_shoot)
		
		# Set muzzle flash position, play animation
		if !is_scoped:
			muzzle.play("default")
			
			muzzle.rotation_degrees.z = randf_range(-45, 45)
			muzzle.scale = Vector3.ONE * randf_range(0.40, 0.75)
			muzzle.position = self.position - weapon.muzzle_position
		
		blaster_cooldown.start(weapon.cooldown)
		
		#TODO: Burst & Projectile logic
		# Shoot the weapon, amount based on shot count
		if weapon.primary_projectile == "proj_hitscan":
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
				
				#TODO: bulletholes
				var impact = preload("res://scenes/objects/actors/fx/impact.tscn")
				var impact_instance = impact.instantiate()
				
				impact_instance.play("shot")
				
				get_tree().root.add_child(impact_instance)
				
				impact_instance.position = raycast.get_collision_point() + (raycast.get_collision_normal() / 10)
				impact_instance.look_at(camera.global_transform.origin, Vector3.UP, true)
		else:
			fire_projectile()
			
		#TODO: a way cooler system that uses the weapon's damage and clamping.
		self.position.z += 0.25 # Knockback of weapon visual
		self.position.x += randf_range(-0.10, 0.10)
		self.position.y -= 0.1
		
		#TODO: true recoil e.g. kicks your view up and you must control it.
		camera.rotation.x += 0.025 # Knockback of camera
		camera.rotation.z += randf_range(-0.025, 0.025) # Left/Right Bob
		player.movement_velocity += Vector3(0, 0, weapon.knockback) # Knockback
		#NOTE: Fix movement, it isn't working :(

# Secondary Attack. Maybe it should be built into the regular shoot because of repeats?
# It would probably be full of repeats anyway, best to just keep it separate I guess.
func action_shoot_secondary():
	if !weapon.has_secondary_attack:
		return
	else:
		if Input.is_action_pressed("shoot_secondary"):
		
			if !blaster_cooldown.is_stopped(): return # Cooldown for shooting
			
			Audio.play(weapon.sound_shoot_secondary)
			
			# Set muzzle flash position, play animation
			
			muzzle.play("default")
			
			muzzle.rotation_degrees.z = randf_range(-45, 45)
			muzzle.scale = Vector3.ONE * randf_range(0.40, 0.75)
			muzzle.position = self.position - weapon.muzzle_position
			
			blaster_cooldown.start(weapon.cooldown_secondary)
			
			# Shoot the weapon, amount based on shot count
			
			for n in weapon.shot_count_secondary:
			
				secondary_ray.target_position.x = randf_range(-weapon.spread_secondary, weapon.spread_secondary)
				secondary_ray.target_position.y = randf_range(-weapon.spread_secondary, weapon.spread_secondary)
				
				secondary_ray.force_raycast_update()
				
				if !secondary_ray.is_colliding(): continue # Don't create impact when raycast didn't hit
				
				var collider = secondary_ray.get_collider()
				
				# Hitting an enemy
				
				if collider.has_method("damage"):
					collider.damage(weapon.damage_secondary)
				
				# Creating an impact animation
				
				var impact = preload("res://scenes/objects/actors/fx/impact.tscn")
				var impact_instance = impact.instantiate()
				
				impact_instance.play("shot")
				
				get_tree().root.add_child(impact_instance)
				
				impact_instance.position = secondary_ray.get_collision_point() + (secondary_ray.get_collision_normal() / 10)
				impact_instance.look_at(camera.global_transform.origin, Vector3.UP, true)
			
			self.position.z += 0.25 # Knockback of weapon visual
			camera.rotation.x += 0.025 # Knockback of camera
			player.movement_velocity += Vector3(0, 0, weapon.knockback_secondary) # Knockback
			#NOTE: Fix movement, it isn't working :(

#TODO: Could probably simplify a bit.
# Scope or Irons
#TODO: Change player mouse speed and joystick speed based on FOV.
func action_scope(force_unzoom : bool):
	if force_unzoom && is_scoped:
		self.visible = true
		Audio.play("sounds/actors/fx/minimize_003.ogg")
		camera.set_fov(player.default_fov)
		is_scoped = false
	else:
		if Input.is_action_just_pressed("weapon_scope"):
			if is_scoped:
				self.visible = true
				Audio.play("sounds/actors/fx/minimize_003.ogg")
				camera.set_fov(player.default_fov)
				is_scoped = false
			else:
				self.visible = false
				Audio.play("sounds/actors/fx/maximize_003.ogg")
				is_scoped = true
				camera.set_fov(weapon.scope_fov)
	
# Toggle between available weapons (listed in 'weapons')
#TODO: Probably replace with an addon for a weapon wheel or something better.
func action_weapon_toggle():
	var old_weapon_index = weapon_index
	if Input.is_action_just_pressed("weapon_toggle"):
		weapon_index = wrap(weapon_index + 1, 0, weapons.size())
	
	if Input.is_action_just_pressed("weapon_toggle_back"):
		weapon_index = wrap(weapon_index - 1, 0, weapons.size())

	if weapon_index != old_weapon_index:
		action_scope(true)
		Audio.play("sounds/actors/player/weapons/weapon_change.ogg")
		initiate_change_weapon(weapon_index)

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
	weapon_model = weapon.model.instantiate()
	self.add_child(weapon_model)
	
	weapon_model.position = weapon.position
	weapon_model.rotation_degrees = weapon.rotation
	
	# Step 3. Set model to only render on layer 2 (the weapon camera)
	for child in weapon_model.find_children("*", "MeshInstance3D"):
		child.layers = 2
		
	# Set weapon data
	
	#TODO: Maybe a whole raycast grabbing system that grabs from the weapon resource. 
	#would be good for shells, muzzles, and specific spray pattern weapons
	raycast.target_position = Vector3(0, 0, -1) * weapon.max_distance
	secondary_ray.target_position = Vector3(0, 0, -1) * weapon.max_distance_secondary
	projectile_ray.target_position = Vector3(0, 0, -1) * weapon.max_distance 
	#max_distance should affect the life and speed of a rocket imo
	get_tree().call_group("GUI", "update_crosshair", weapon.crosshair)
	
