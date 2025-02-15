extends Resource
class_name Pickup

@export_subgroup("Model & Sound")
@export var model: PackedScene
@export var position: Vector3
@export var rotation: Vector3
@export var scale: Vector3
@export var sound_pickup: String

@export_subgroup("Properties")
@export var drop_ammo: bool
@export var drop_weapon: bool
@export var drop_health: bool

#@export var drop_: bool
#@export var drop_: bool
#@export var pickup_id: int # what pickup


@export_subgroup("Ammo")
@export_enum("ammo_clip", "ammo_shell") var ammo_type: String = "ammo_clip"
#@export var ammo_id: (int, "Pistol", "Shotgun", "Rifle")
@export var ammo_amount: int

@export_subgroup("Weapon")
@export var weapon_id: Weapon  # Sound path
@export var weapon_pickup_ammo: int #If this is a weapon pickup, this will be used to give free ammo of the ammo_type value.

@export_subgroup("Health")
@export var health_amount: int
