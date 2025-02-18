##Originally inside player.gd. Controls which weapon resource is loaded and actually attacks with them.

extends Node3D

class_name WeaponBaseComponent

@export var weapon_manager: WeaponManagerComponent
@export var blaster_cooldown: Timer
@export var muzzle: AnimatedSprite3D
@onready var sfx_weapon_fire: AudioStreamPlayer = $sfx_weapon_fire
@onready var sfx_weapon_foley: AudioStreamPlayer = $sfx_weapon_foley

#I feel this is probably clunky and not very elegant but it works for storing all the weapon stats, which are used in the attack function and means I don't need -
# - To have a "secondary attack" func, reducing reptition.

var primary_stats: Dictionary
var secondary_stats: Dictionary
var misc_stats: Dictionary

var primary_can_fire = true
var secondary_can_fire = true

var weapon_model = null
var tween:Tween
var weapon: Weapon

var is_scoped: bool = false

func _process(_delta: float) -> void:
	if Input.is_action_pressed("shoot") || Input.is_action_pressed("shoot_secondary"):
		action_prepare_shoot()
	
	#if weapon.primary_is_semiauto:
		#if Input.is_action_just_released("shoot"):
			#primary_can_fire = true
		#else:
			#primary_can_fire = false
		#
	#if weapon.secondary_is_semiauto:
		#if Input.is_action_just_released("shoot_secondary"):
			#secondary_can_fire = true
		
	#print("Can Semi Fire?: " + str(primary_can_fire))
	action_scope(false)
	crosshair_awareness()

#region Attack & Weapon Ability Logic
func action_prepare_shoot():
	if !blaster_cooldown.is_stopped(): 
		return  # Cooldown for shooting
	else:
		if Input.is_action_pressed("shoot"):
			action_shoot(false, primary_stats) #TODO: add seoncdary attack to data
		if Input.is_action_pressed("shoot_secondary") && misc_stats.get("has secondary attack"):
			action_shoot(true, secondary_stats)

# Shooting
func action_shoot(secondary_attack: bool, chosen_stats: Dictionary):
	sfx_weapon_fire.set_stream(load(chosen_stats.get("attack sound")))
	sfx_weapon_fire.play()
	blaster_cooldown.start(chosen_stats.get("cooldown"))
	# Set muzzle flash position, play animation
	#TODO: check if this weapon should be hidden when zoomed vs not.
	if !is_scoped:
		muzzle.play("default")
		muzzle.rotation_degrees.z = randf_range(-45, 45)
		muzzle.scale = Vector3.ONE * randf_range(0.40, 0.75)
		muzzle.position = weapon_manager.position - weapon_manager.weapon.muzzle_position

	#TODO: Burst & Projectile logic
	#TODO: Separate the actual firing logic into its own function.
	# Shoot the weapon, amount based on shot count
	
	#TODO: Should more consistently reference the weapon data.
	#TODO: Consider secondary attack projectiles
	if !chosen_stats.get("uses projectile"): #NOTE: change this later to the chosen stats once projectile logic finalized
		fire_hitscan(chosen_stats, secondary_attack)
	else:
		fire_projectile(chosen_stats)
	handle_recoil(chosen_stats)

#TODO: this code needs serious work later.
func fire_projectile(chosen_stats: Dictionary):
	var proj
	proj = chosen_stats.get("projectile scene").instantiate()
	
	#TODO: Follow Chaff Games' guide on raycast so they come from center of screen.
	proj.position = weapon_manager.projectile_raycast.global_position
	proj.transform.basis = weapon_manager.projectile_raycast.global_transform.basis
	
	#TODO: Fix these
	#proj.position.x = randf_range(-weapon.spread, weapon.spread)
	#proj.position.y = randf_range(-weapon.spread, weapon.spread)
			
	get_tree().root.add_child(proj)
func fire_hitscan(chosen_stats: Dictionary, use_secondary_ray: bool):
	#Probably a way cooler way of doing this?
	var chosen_ray:RayCast3D
	if !use_secondary_ray:
		chosen_ray = weapon_manager.primary_raycast
	else:
		chosen_ray = weapon_manager.secondary_raycast
			
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
		
		#TODO: Impact should be its own scene so it can do cool stuff like play audio
		impact_instance.position = chosen_ray.get_collision_point() + (chosen_ray.get_collision_normal() / 10)
		impact_instance.look_at(weapon_manager.player.camera.global_transform.origin, Vector3.UP, true)


# Scope or Irons
func action_scope(force_unzoom : bool):
#TODO: Could probably simplify a bit.
#TODO: Change player mouse speed and joystick speed based on FOV. Need a good formula!
	if force_unzoom && is_scoped:
		self.visible = true
		sfx_weapon_foley.set_stream(load("sounds/actors/fx/minimize_003.ogg"))
		sfx_weapon_foley.play()
		weapon_manager.player.camera.set_fov(weapon_manager.player.default_fov)
		is_scoped = false
	else:
		if Input.is_action_just_pressed("weapon_scope"):
			if is_scoped:
				self.visible = true
				sfx_weapon_foley.set_stream(load("sounds/actors/fx/minimize_003.ogg"))
				sfx_weapon_foley.play()
				weapon_manager.player.camera.set_fov(weapon_manager.player.default_fov)
				is_scoped = false
			else:
				self.visible = false
				sfx_weapon_foley.set_stream(load("sounds/actors/fx/maximize_003.ogg"))
				sfx_weapon_foley.play()
				is_scoped = true
				weapon_manager.player.camera.set_fov(misc_stats.get("scope fov"))
#endregion

#region GUI/UI & Feedback
func handle_recoil(chosen_stats : Dictionary):
	#TODO: a way cooler system that uses the weapon's damage and clamping.
	weapon_manager.position.z += 0.25 # Knockback of weapon visual
	weapon_manager.position.x += randf_range(-0.10, 0.10)
	weapon_manager.position.y -= 0.1
	
	#TODO: true recoil e.g. kicks your view up and you must control it.
	weapon_manager.player.camera.rotation.x += 0.025 # Knockback of camera
	weapon_manager.player.camera.rotation.z += randf_range(-0.025, 0.025) # Left/Right Bob
	weapon_manager.player.movement_velocity += Vector3(0, 0, chosen_stats.get("knockback")) # Knockback
	#NOTE: Fix movement, it isn't working :(
	
	#Color Crosshair Red ala Halo
func crosshair_awareness():
	var active_ray = null
	
	if weapon_manager.primary_raycast.is_colliding():
		active_ray = weapon_manager.primary_raycast
	elif weapon_manager.secondary_raycast.is_colliding():
		active_ray = weapon_manager.secondary_raycast
		
	if active_ray != null:
		var collider = active_ray.get_collider()
		if collider != null && collider.is_in_group("mobs"):
			get_tree().call_group("GUI", "update_crosshair_color", true)
	else:
		get_tree().call_group("GUI", "update_crosshair_color", false)
#endregion
