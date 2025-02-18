##Originally inside player.gd. Controls which weapon resource is loaded and actually attacks with them.

extends Node3D

class_name WeaponManager

@export var  player: DM23Player

@onready var blaster_cooldown: Timer = $"../../../../../../../Cooldown"
@onready var raycast: RayCast3D = $"../../../../RayCast"
@onready var secondary_ray: RayCast3D = $"../../../../Secondary_Attack_Ray"
@onready var projectile_ray: RayCast3D = $"../../../../Projectile_Ray"

@onready var muzzle = $"../Muzzle"
@onready var camera = $"../../../.."

@export_subgroup("Weapons")
@export var weapons: Array[Weapon] = []

#I feel this is probably clunky and not very elegant but it works for storing all the weapon stats, which are used in the attack function and means I don't need -
# - To have a "secondary attack" func, reducing reptition.

var primary_stats: Dictionary
var secondary_stats: Dictionary

var primary_can_fire = true
var secondary_can_fire = true

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

#I figure it is probably best for everything to be in the process tick instead of physics? - 
#- Only physics is the raycasts and that should be fine here.
func _process(_delta: float) -> void:
	if Input.is_action_pressed("shoot") || Input.is_action_pressed("shoot_secondary"):
		action_prepare_shoot()
	
	if weapon.primary_is_semiauto:
		if Input.is_action_just_released("shoot"):
			primary_can_fire = true
		else:
			primary_can_fire = false
		
	if weapon.secondary_is_semiauto:
		if Input.is_action_just_released("shoot_secondary"):
			secondary_can_fire = true
		
	print("Can Semi Fire?: " + str(primary_can_fire))
	action_scope(false)
	action_weapon_toggle()
	crosshair_awareness()
	
#Color Crosshair Red ala Halo
func crosshair_awareness():
	var active_ray = null
	
	if raycast.is_colliding():
		active_ray = raycast
	elif secondary_ray.is_colliding():
		active_ray = secondary_ray
		
	if active_ray != null:
		var collider = active_ray.get_collider()
		if collider != null && collider.is_in_group("mobs"):
			get_tree().call_group("GUI", "update_crosshair_color", true)
	else:
		get_tree().call_group("GUI", "update_crosshair_color", false)

func action_prepare_shoot():
	if !blaster_cooldown.is_stopped(): return # Cooldown for shooting
	else:
		if Input.is_action_pressed("shoot"):
			action_shoot(false, primary_stats)
		if Input.is_action_pressed("shoot_secondary") && weapon.has_secondary_attack:
			action_shoot(true, secondary_stats)

# Shooting
func action_shoot(secondary_attack: bool, chosen_stats: Dictionary):
	
	Audio.play(chosen_stats.get("shoot sound"))
	blaster_cooldown.start(chosen_stats.get("cooldown"))
	# Set muzzle flash position, play animation
	#TODO: check if this weapon should be hidden when zoomed vs not.
	if !is_scoped:
		muzzle.play("default")
		muzzle.rotation_degrees.z = randf_range(-45, 45)
		muzzle.scale = Vector3.ONE * randf_range(0.40, 0.75)
		muzzle.position = self.position - weapon.muzzle_position

	#TODO: Burst & Projectile logic
	#TODO: Separate the actual firing logic into its own function.
	# Shoot the weapon, amount based on shot count
	
	if weapon.primary_projectile == "proj_hitscan": #NOTE: change this later to the chosen stats once projectile logic finalized
		fire_hitscan(chosen_stats, secondary_attack)
	else:
		fire_projectile(chosen_stats)
		
	#TODO: a way cooler system that uses the weapon's damage and clamping.
	self.position.z += 0.25 # Knockback of weapon visual
	self.position.x += randf_range(-0.10, 0.10)
	self.position.y -= 0.1
	
	#TODO: true recoil e.g. kicks your view up and you must control it.
	camera.rotation.x += 0.025 # Knockback of camera
	camera.rotation.z += randf_range(-0.025, 0.025) # Left/Right Bob
	player.movement_velocity += Vector3(0, 0, chosen_stats.get("knockback")) # Knockback
	#NOTE: Fix movement, it isn't working :(

#TODO: this code needs serious work later.
func fire_projectile(chosen_stats: Dictionary):
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

func fire_hitscan(chosen_stats: Dictionary, use_secondary_ray: bool):
	#Probably a way cooler way of doing this?
	var chosen_ray:RayCast3D
	if !use_secondary_ray:
		chosen_ray = raycast
	else:
		chosen_ray = secondary_ray
			
	for n in chosen_stats.get("shot count"):
		chosen_ray.target_position.x = randf_range(-chosen_stats.get("spread"), chosen_stats.get("spread"))
		chosen_ray.target_position.y = randf_range(-chosen_stats.get("spread"), chosen_stats.get("spread"))
		
		chosen_ray.force_raycast_update()
		
		if !chosen_ray.is_colliding(): continue # Don't create impact when raycast didn't hit
		
		var collider = chosen_ray.get_collider()
		
		# Hitting an enemy
		
		if collider is HitBoxComponent:
			collider.give_damage(chosen_stats.get("damage"))
		
		# Creating an impact animation
		
		#TODO: bulletholes
		var impact = preload("res://scenes/objects/actors/fx/impact.tscn")
		var impact_instance = impact.instantiate()
		
		impact_instance.play("shot")
		
		get_tree().root.add_child(impact_instance)
		
		impact_instance.position = chosen_ray.get_collision_point() + (chosen_ray.get_collision_normal() / 10)
		impact_instance.look_at(camera.global_transform.origin, Vector3.UP, true)

# Scope or Irons
func action_scope(force_unzoom : bool):
#TODO: Could probably simplify a bit.
#TODO: Change player mouse speed and joystick speed based on FOV. Need a good formula!	
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
func action_weapon_toggle():
#TODO: Probably replace with an addon for a weapon wheel or something better.	
	var old_weapon_index = weapon_index
	if Input.is_action_just_pressed("weapon_toggle"):
		weapon_index = wrap(weapon_index + 1, 0, weapons.size())
	
	if Input.is_action_just_pressed("weapon_toggle_back"):
		weapon_index = wrap(weapon_index - 1, 0, weapons.size())

	#This runs all the time but never changes unless we press the change buttons
	#Should probably fix it but eh. I guess later TODO
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

func load_weapon_data(current_weapon_data: Weapon):
	primary_stats = {
	"shoot sound" = current_weapon_data.primary_sound_shoot,
	"ammo consumption" = current_weapon_data.primary_ammo_consumption,
	"cooldown" = current_weapon_data.primary_cooldown,
	"max_distance"= current_weapon_data.primary_max_distance,
	"damage"= current_weapon_data.primary_damage,
	"spread"= current_weapon_data.primary_spread,
	"shot count"= current_weapon_data.primary_shot_count,
	"knockback"= current_weapon_data.primary_knockback,
	"burst count"= current_weapon_data.primary_burst_count,
	"burst cooldown"= current_weapon_data.primary_burst_cooldown
	}

	secondary_stats = {
	"shoot sound" = current_weapon_data.secondary_sound_shoot,
	"ammo consumption" = current_weapon_data.secondary_ammo_consumption,
	"cooldown" = current_weapon_data.secondary_cooldown,
	"max_distance"= current_weapon_data.secondary_max_distance,
	"damage"= current_weapon_data.secondary_damage,
	"spread"= current_weapon_data.secondary_spread,
	"shot count"= current_weapon_data.secondary_shot_count,
	"knockback"= current_weapon_data.secondary_knockback,
	"burst count"= current_weapon_data.secondary_burst_count,
	"burst cooldown"= current_weapon_data.secondary_burst_cooldown
	}
	
# Switches the weapon model (off-screen)
func change_weapon():
	
	#TODO: Implement a simple state system so weapons cannot fire until drawn fully.
	
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
	load_weapon_data(weapon)
	
	#TODO: Maybe a whole raycast grabbing system that grabs from the weapon resource. 
	#would be good for shells, muzzles, and specific spray pattern weapons
	
	#TODO: these should be set in the weapon data func too
	raycast.target_position = Vector3(0, 0, -1) * weapon.primary_max_distance
	secondary_ray.target_position = Vector3(0, 0, -1) * weapon.secondary_max_distance
	projectile_ray.target_position = Vector3(0, 0, -1) * weapon.primary_max_distance 
	#max_distance should affect the life and speed of a rocket imo
	get_tree().call_group("GUI", "update_crosshair", weapon.crosshair)
