extends Resource
class_name Weapon

@export_group("Graphics & Audio")

@export_subgroup("Model")
@export var model: PackedScene  # Model of the weapon
@export var position: Vector3  # On-screen position
@export var rotation: Vector3  # On-screen rotation
@export var muzzle_position: Vector3  # On-screen position of muzzle flash

@export_subgroup("2D Art")
@export var crosshair: Texture2D  # Image of crosshair on-screen
@export var inventory_icon: Texture2D # 2D image of the weapon for HUD / UI.

@export_subgroup("Audio")
@export var primary_sound_shoot: String  # Sound path
@export var secondary_sound_shoot: String  # Sound path

@export_group("General Properties")
@export var weapon_name: String = "Rifle" #Name used for HUD / UI & Print statements

@export var primary_is_semiauto: bool = false # If Semiauto Attack TODO: Logic
@export var secondary_is_semiauto: bool = false # If Semiauto Attack TODO: Logic

@export var primary_is_charge: bool = false # If Charge Attack TODO: Logic
@export var secondary_is_charge: bool = false # If Charge Attack TODO: Logic
@export var primary_is_burst_fire: bool = false # If Burst Fire TODO: Logic
@export var secondary_is_burst_fire: bool = false # If Burst Fire TODO: Logic
@export var has_secondary_attack: bool # If has secondary fire

#TODO: Placeholder for future logic. Some weapons may require a bespoke, unique way of firing or attacking and this is to future proof a little bit.
#@export var primary_override: bool
#@export var secondary_override:bool
 
@export_range(25, 70) var scope_fov: float = 65


@export_group("Projectile & Ammo Properties")
#TODO: Better tooling where groups are hidden based on booleans.
#TODO: Look into more dynamic system where we just grab whatever projectile is set, instead of this manual system.

#PLACEHOLDER UNTIL NEW TOOL AND LOGIC FOR PROJECTILE SELECTION
@export var projectile: PackedScene  # Model of the weapon

#TODO: THESE TWO WILL BE REPLACED ONCE TOOL LOGIC IS IMPLEMENTED INTO MENU
@export_enum("proj_hitscan", "proj_rocket", "proj_grenade") var primary_projectile: String = "proj_hitscan"
@export_enum("proj_hitscan", "proj_rocket", "proj_grenade") var secondary_projectile: String = "proj_hitscan"


@export_enum("ammo_null","ammo_clip", "ammo_shell") var primary_ammo_type: String = "ammo_clip"
@export_range (0, 100) var primary_ammo_consumption: int = 1

@export_enum("ammo_null","ammo_clip", "ammo_shell") var secondary_ammo_type: String = "ammo_clip"
@export_range (0, 100) var secondary_ammo_consumption: int = 1

@export_group("Primary Attack")
@export_range(0.1, 1) var primary_cooldown: float = 0.1  # Firerate
@export_range(1, 20) var primary_max_distance: int = 10  # Fire distance #TODO: Affect projectiles
@export_range(0, 100) var primary_damage: float = 25  # Damage per hit #TODO: Affect projectiles
@export_range(0, 5) var primary_spread: float = 0  # Spread of each shot #TODO: Affect projectiles
@export_range(1, 30) var primary_shot_count: int = 1  # Amount of shots
@export_range(0, 50) var primary_knockback: int = 20  # Amount of knockback

@export_range(2, 50) var primary_burst_count: int = 2 # Amount of Bursts
@export_range (0.01, 1) var primary_burst_cooldown: float = 0.1 # Delay between burst shots

@export_group("Secondary Attack")
@export_range(0.1, 1) var secondary_cooldown: float = 0.1  # Firerate
@export_range(1, 20) var secondary_max_distance: int = 10  # Fire distance
@export_range(0, 100) var secondary_damage: float = 25  # Damage per hit
@export_range(0, 5) var secondary_spread: float = 0  # Spread of each shot
@export_range(1, 30) var secondary_shot_count: int = 1  # Amount of shots
@export_range(0, 50) var secondary_knockback: int = 20  # Amount of knockback

@export_range(2, 50) var secondary_burst_count: int = 2 # Amount of Bursts
@export_range (0.01, 1) var secondary_burst_cooldown: float = 0.1 # Delay between burst shots
