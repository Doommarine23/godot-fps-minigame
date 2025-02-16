extends Resource
class_name Weapon

@export_subgroup("Model")
@export var model: PackedScene  # Model of the weapon
@export var position: Vector3  # On-screen position
@export var rotation: Vector3  # On-screen rotation
@export var muzzle_position: Vector3  # On-screen position of muzzle flash

@export_subgroup("General Properties")
@export var projectile_type: String #If we're hitscan or a projectile.
@export var has_secondary_attack: bool # If has secondary fire
@export_range(25, 70) var scope_fov: float = 65
@export var sound_shoot: String  # Sound path
@export var sound_shoot_secondary: String  # Sound path
@export var crosshair: Texture2D  # Image of crosshair on-screen
@export var inventory_icon: Texture2D # 2D image of the weapon for HUD / UI.

@export_subgroup("Primary Properties")
@export_range(0.1, 1) var cooldown: float = 0.1  # Firerate
@export_range(1, 20) var max_distance: int = 10  # Fire distance
@export_range(0, 100) var damage: float = 25  # Damage per hit
@export_range(0, 5) var spread: float = 0  # Spread of each shot
@export_range(1, 5) var shot_count: int = 1  # Amount of shots
@export_range(0, 50) var knockback: int = 20  # Amount of knockback

@export_subgroup("Secondary Properties")
@export_range(0.1, 1) var cooldown_secondary: float = 0.1  # Firerate
@export_range(1, 20) var max_distance_secondary: int = 10  # Fire distance
@export_range(0, 100) var damage_secondary: float = 25  # Damage per hit
@export_range(0, 5) var spread_secondary: float = 0  # Spread of each shot
@export_range(1, 5) var shot_count_secondary: int = 1  # Amount of shots
@export_range(0, 50) var knockback_secondary: int = 20  # Amount of knockback
