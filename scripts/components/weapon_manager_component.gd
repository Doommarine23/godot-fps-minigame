##Originally inside player.gd. Controls which weapon resource is loaded and actually attacks with them.

extends Node3D

class_name WeaponManagerComponent

@export_subgroup("Required Components")
@export var player: DM23Player
@export var weapon_component: WeaponBaseComponent

@onready var soundFX: AudioStreamPlayer = $SoundFX

@export var primary_raycast: RayCast3D
@export var secondary_raycast: RayCast3D
@export var projectile_raycast: RayCast3D

@export_subgroup("Weapon Inventory")
@export var weapons: Array[Weapon] = []

#I feel this is probably clunky and not very elegant but it works for storing all the weapon stats, which are used in the attack function and means I don't need -
# - To have a "secondary attack" func, reducing reptition.

var primary_stats: Dictionary
var secondary_stats: Dictionary

var weapon_model = null
var tween:Tween
var weapon: Weapon
var weapon_index := 0
var container_offset = Vector3(1.2, -1.1, -2.75)
var scope_fov

func _ready() -> void:
	weapon = weapons[weapon_index] # Weapon must never be nil TODO: Add a "no weapons" weapon ala Halo.
	initiate_change_weapon(weapon_index)

func _process(_delta: float) -> void:
	action_weapon_toggle()

func _physics_process(delta: float) -> void:
	pass #weapon_component.position = self.position
# Toggle between available weapons (listed in 'weapons')
func action_weapon_toggle():
#TODO: Probably replace with an addon for a weapon wheel or something better.
	var old_weapon_index = weapon_index
	var request_change = false
	if Input.is_action_just_pressed("weapon_toggle"):
		weapon_index = wrap(weapon_index + 1, 0, weapons.size())
		request_change = true
	
	if Input.is_action_just_pressed("weapon_toggle_back"):
		weapon_index = wrap(weapon_index - 1, 0, weapons.size())
		request_change = true

	#This runs all the time but never changes unless we press the change buttons
	#Should probably fix it but eh. I guess later TODO
	if weapon_index != old_weapon_index && request_change:
		soundFX.set_stream( load("sounds/actors/player/weapons/weapon_change.ogg") )
		soundFX.play()
		initiate_change_weapon(weapon_index)

# Initiates the weapon changing animation (tween)
func initiate_change_weapon(index):
	weapon_index = index
	
	tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.tween_property(self, "position", container_offset - Vector3(0, 1, 0), 0.1)
	tween.tween_callback(change_weapon) # Changes the model

func change_weapon():
	
	#TODO: Implement a simple state system so weapons cannot fire until drawn fully.
	
	weapon = weapons[weapon_index]
	## Step 1. Remove previous weapon model(s) from container
	for n in weapon_component.get_children():
		weapon_component.remove_child(n)
	
	## Step 2. Add to Weapon Component
	weapon_component.weapon_model = weapon.model.instantiate()
	weapon_component.add_child(weapon_component.weapon_model)
	weapon_component.position = weapon.position
	weapon_component.rotation_degrees = weapon.rotation
	weapon_component.add_child(weapon_component.sfx_weapon_fire) #It doesn't add its own child I don't understand???
	weapon_component.add_child(weapon_component.sfx_weapon_foley) #It doesn't add its own child I don't understand???
	#weapon_component.audio_stream_player_3d.position = weapon_component.position
	
	#weapon_component.weapon_model.layers = 2
	# Step 3. Set model to only render on layer 2 (the weapon camera)
	for child in weapon_component.weapon_model.find_children("*", "MeshInstance3D"):
		child.layers = 2
		
	# Set weapon data
	load_weapon_data(weapon)
	weapon_component.primary_stats = primary_stats
	weapon_component.secondary_stats = secondary_stats

func load_weapon_data(current_weapon_data: Weapon):
	#TODO: Maybe a whole raycast grabbing system that grabs from the weapon resource. 
	#would be good for shells, muzzles, and specific spray pattern weapons

	#max_distance should affect the life and speed of a rocket imo
	primary_raycast.target_position = Vector3(0, 0, -1) * weapon.primary_max_distance
	secondary_raycast.target_position = Vector3(0, 0, -1) * weapon.secondary_max_distance
	projectile_raycast.target_position = Vector3(0, 0, -1) * weapon.primary_max_distance 
	scope_fov = weapon.scope_fov
	
	#Update Crosshair
	get_tree().call_group("GUI", "update_crosshair", weapon.crosshair)
	
	#Get Weapon Attack Stats
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
