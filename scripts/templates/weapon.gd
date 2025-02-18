extends Resource
class_name Weapon


#TODO: Placeholder for future logic. Some weapons may require a bespoke, unique way of firing or attacking and this is to future proof a little bit.
#@export var primary_override: bool
#@export var secondary_override:bool

@export_group("Graphics & Audio")

@export_subgroup("Model")
@export var model: PackedScene  ## Model of the weapon
@export var position: Vector3  ## On-screen position
@export var rotation: Vector3  ## On-screen rotation
#TODO:Define positions on model scenes where shells and muzzles exist from
@export var muzzle_position: Vector3  ## On-screen position of muzzle flash

@export_subgroup("2D Art")
@export var crosshair: Texture2D  ## Image of crosshair on-screen
@export var inventory_icon: Texture2D ## 2D image of the weapon for HUD / UI.

@export_subgroup("Audio")
@export var primary_sound_shoot: String  ## Sound path
@export var secondary_sound_shoot: String  ## Sound path

@export_group("General Properties")
@export var weapon_name: String = "Rifle" ##Name used for HUD / UI & Print statements
@export var has_secondary_attack: bool = false ## If has secondary fire
@export_range(25, 70) var scope_fov: float = 65 ##Amount of Zoom when scoped


@export_group("Primary Properties")
@export_subgroup("Attack Behaviors")
@export var primary_is_semiauto: bool = false ## If Semiauto Attack TODO: Logic
@export var primary_is_burst_fire: bool = false ## If Burst Fire TODO: Logic
@export var primary_is_charge: bool = false ## If Charge Attack TODO: Logic

@export_subgroup("Burst Statistics")
@export_range(2, 50) var primary_burst_count: int = 2 ## Amount of Bursts
@export_range (0.01, 1) var primary_burst_cooldown: float = 0.1 ## Delay between burst shots

@export_subgroup("Charge Statistics")
@export_range(1, 50) var primary_charge_levels: int = 2 ## Levels of Charge
@export_range (0.1, 5) var primary_charge_time_per_level: float = 0.5 ## Delay between Charges

@export_subgroup("Ammo & Projectile Properties")
@export var primary_uses_ammo: bool = true ##If uses ammo
@export_range (0, 100) var primary_ammo_consumption: int = 1 ##Ammo used per shot
@export_enum("ammo_null","ammo_clip", "ammo_shell") var primary_ammo_type: String = "ammo_clip" ##Ammo Type
@export var primary_uses_projectile: bool = false ##If false, uses hitscan, otherwise fires projectile scene
@export var primary_projectile: PackedScene  ## Projectile Scene

@export_subgroup("Attack Stats")
@export_range(0.1, 1) var primary_cooldown: float = 0.1  ## Firerate
@export_range(1, 20) var primary_max_distance: int = 10  ## Fire distance #TODO: Affect projectiles
@export_range(0, 100) var primary_damage: float = 25  ## Damage per hit #TODO: Affect projectiles
@export_range(0, 5) var primary_spread: float = 0  ## Spread of each shot #TODO: Affect projectiles
@export_range(1, 30) var primary_shot_count: int = 1  ## Amount of shots
@export_range(0, 50) var primary_knockback: int = 20  ## Amount of knockback

@export_group("Secondary Properties")
@export_subgroup("Attack Behaviors")
@export var secondary_is_semiauto: bool = false ## If Semiauto Attack TODO: Logic
@export var secondary_is_burst_fire: bool = false ## If Burst Fire TODO: Logic
@export var secondary_is_charge: bool = false ## If Charge Attack TODO: Logic

@export_subgroup("Burst Statistics")
@export_range(2, 50) var secondary_burst_count: int = 2 ## Amount of Bursts
@export_range (0.01, 1) var secondary_burst_cooldown: float = 0.1 ## Delay between burst shots

@export_subgroup("Charge Statistics")
@export_range(1, 50) var secondary_charge_levels: int = 2 ## Levels of Charge
@export_range (0.1, 5) var secondary_charge_time_per_level: float = 0.5 ## Delay between Charges

@export_subgroup("Ammo & Projectile Properties")
@export var secondary_uses_ammo: bool = true ##If uses ammo
@export_range (0, 100) var secondary_ammo_consumption: int = 1 ##Ammo used per shot
@export_enum("ammo_null","ammo_clip", "ammo_shell") var secondary_ammo_type: String = "ammo_clip" ##Ammo Type
@export var secondary_uses_projectile: bool = false ##If false, uses hitscan, otherwise fires projectile scene
@export var secondary_projectile: PackedScene  ## Projectile Scene

@export_subgroup("Attack Stats")
@export_range(0.1, 1) var secondary_cooldown: float = 0.1  ## Firerate
@export_range(1, 20) var secondary_max_distance: int = 10  ## Fire distance #TODO: Affect projectiles
@export_range(0, 100) var secondary_damage: float = 25  ## Damage per hit #TODO: Affect projectiles
@export_range(0, 5) var secondary_spread: float = 0  ## Spread of each shot #TODO: Affect projectiles
@export_range(1, 30) var secondary_shot_count: int = 1  ## Amount of shots
@export_range(0, 50) var secondary_knockback: int = 20  ## Amount of knockback

#We grab all these stats, slot them into two dictionaries and shove that payload into an array
#This is requested by the weapon manager which then uses them for the weapon data in-gameplay.
func setup_weapon() -> Array:
	var misc_stats = {
	"has secondary attack" = has_secondary_attack,
	"scope fov" = scope_fov
	}
	var primary_stats = {
	#Audio
	"attack sound" = primary_sound_shoot,
	#Attack Behaviors 
	"is semiautomatic" = primary_is_semiauto,
	"is burst fire" = primary_is_burst_fire,
	"is charge" = primary_is_charge,
	#Burst Stats 
	"burst count" = primary_burst_count,
	"burst cooldown" = primary_burst_cooldown,
	#Charge Stats
	"charge levels" = primary_charge_levels,
	"charge time per level" = primary_charge_time_per_level,
	#Ammo & Projectile Properties
	"uses ammo" = primary_uses_ammo,
	"ammo per shot" = primary_ammo_consumption,
	"ammo type" = primary_ammo_type,
	"uses projectile" = primary_uses_projectile,
	"projectile scene" = primary_projectile,
	#Attack Stats
	"cooldown" = primary_cooldown,
	"max distance" = primary_max_distance,
	"damage" = primary_damage,
	"spread" = primary_spread,
	"shot count" = primary_shot_count,
	"knockback" = primary_knockback
	}
	
	var secondary_stats = {
	#Audio
	"attack sound" = secondary_sound_shoot,	
	#Attack Behaviors 
	"is semiautomatic" = secondary_is_semiauto,
	"is burst fire" = secondary_is_burst_fire,
	"is charge" = secondary_is_charge,
	#Burst Stats 
	"burst count" = secondary_burst_count,
	"burst cooldown" = secondary_burst_cooldown,
	#Charge Stats
	"charge levels" = secondary_charge_levels,
	"charge time per level" = secondary_charge_time_per_level,
	#Ammo & Projectile Properties
	"uses ammo" = secondary_uses_ammo,
	"ammo per shot" = secondary_ammo_consumption,
	"ammo type" = secondary_ammo_type,
	"uses projectile" = secondary_uses_projectile,
	"projectile scene" = secondary_projectile,
	#Attack Stats
	"cooldown" = secondary_cooldown,
	"max distance" = secondary_max_distance,
	"damage" = secondary_damage,
	"spread" = secondary_spread,
	"shot count" = secondary_shot_count,
	"knockback" = secondary_knockback
	}
	return [primary_stats, secondary_stats, misc_stats]
