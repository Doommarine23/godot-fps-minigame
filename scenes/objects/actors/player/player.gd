#TODO: Type all variables. Better sanity / safety and slightly better performance.
extends CharacterBody3D

#region Node References
@onready var camera = $Head/Camera
@onready var container = $Head/Camera/SubViewportContainer/SubViewport/CameraItem/Container
@onready var sound_footsteps = $SoundFootsteps
#endregion

#region Variables
@export_subgroup("Properties")
@export var movement_speed = 5
@export var jump_strength = 8
@export var max_health:int = 100

var health:int = 100
var gravity:float = 0.0
var movement_velocity: Vector3
var rotation_target: Vector3

var mouse_captured:bool = true
var mouse_sensitivity = 700
var input_mouse: Vector2
var gamepad_sensitivity:float = 0.075

var default_fov:float = 80.0

var previously_floored:bool = false
var jump_single:bool = true
var jump_double:bool = false
#endregion

#region Player Ammo Pools
#TODO: Once supported, made into INT typed.
#TODO: new manager node?
var ammo_types: Dictionary = {
	"ammo_null" : 0, #Melee and the like.
	"ammo_clip" : 50,
	"ammo_shell" : 5
}

var ammo_types_max: Dictionary = {
	"ammo_null_max" : 0, #Do I really even need this? Just adding it for completeness.
	"ammo_clip_max" : 100,
	"ammo_shell_max" : 20
}

#Perhaps there is a more clever way of doing ammo, perhaps as a multi-dimensional array, to store current, max, and icons.
#TODO: Do these need to be preload?
var ammo_icons: Dictionary = {
	"ammo_null" : "null",
	"ammo_clip" : "null",#preload("bullets.tga"),
	"ammo_shell" : "null",#preload("bullets.tga"),
}
#endregion

#region Signals
signal pickup_detected
signal ammo_updated
signal health_updated
#endregion

# FUNCTIONS

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta):
	handle_mouse_controls(delta)

func _physics_process(delta):
	
	# Handle functions
	
	handle_controls(delta)
	handle_gravity(delta)
	
	# Movement

	var applied_velocity: Vector3
	
	movement_velocity = transform.basis * movement_velocity # Move forward
	
	applied_velocity = velocity.lerp(movement_velocity, delta * 10)
	applied_velocity.y = -gravity
	
	velocity = applied_velocity
	move_and_slide()
	
	# Rotation
	
	camera.rotation.z = lerp_angle(camera.rotation.z, -input_mouse.x * 25 * delta, delta * 5)	
	camera.rotation.x = lerp_angle(camera.rotation.x, rotation_target.x, delta * 25)
	
	rotation.y = lerp_angle(rotation.y, rotation_target.y, delta * 25)
	
	#Weapon Container Rotation
	
	container.position = lerp(container.position, container.container_offset - (basis.inverse() * applied_velocity / 30), delta * 10)
	
	# Movement sound
	
	sound_footsteps.stream_paused = true
	
	if is_on_floor():
		if abs(velocity.x) > 1 or abs(velocity.z) > 1:
			sound_footsteps.stream_paused = false
	
	# Landing after jump or falling
	
	camera.position.y = lerp(camera.position.y, 0.0, delta * 5)
	
	#TODO: Velocity minimum for landing sound.
	if is_on_floor() and gravity > 1 and !previously_floored: # Landed
		Audio.play("sounds/actors/player/movement/land.ogg")
		camera.position.y = -0.1
	
	previously_floored = is_on_floor()
	
	# Falling/respawning
	
	if position.y < -10:
		get_tree().reload_current_scene()

func _input(event):
	if event is InputEventMouseMotion and mouse_captured:
		
		input_mouse = event.relative / mouse_sensitivity
		
		rotation_target.y -= event.relative.x / mouse_sensitivity
		rotation_target.x -= event.relative.y / mouse_sensitivity

# Handle Mouse Control
func handle_mouse_controls(delta):
	# Mouse Capture
	if Input.is_action_just_pressed("mouse_capture"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mouse_captured = true
	
	if Input.is_action_just_pressed("mouse_capture_exit"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouse_captured = false
		
		input_mouse = Vector2.ZERO

# Handle All Other Controls
func handle_controls(_delta):
	# Movement
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	movement_velocity = Vector3(input.x, 0, input.y).normalized() * movement_speed
	
	# Rotation
	var rotation_input := Input.get_vector("camera_right", "camera_left", "camera_down", "camera_up")
	
	rotation_target -= Vector3(-rotation_input.y, -rotation_input.x, 0).limit_length(1.0) * gamepad_sensitivity
	rotation_target.x = clamp(rotation_target.x, deg_to_rad(-90), deg_to_rad(90))
	

	
	# Jumping
	
	if Input.is_action_just_pressed("jump"):
		
		#preferable over a long horizontal line.
		#TODO: should be defined elsewhere with all player sounds but do that later
		var jump_sound = [
		"sounds/actors/player/movement/jump_a.ogg", 
		"sounds/actors/player/movement/jump_b.ogg", 
		"sounds/actors/player/movement/jump_c.ogg"
		]
		
		if jump_single or jump_double:
			Audio.play(jump_sound.pick_random())
			
		#if jump_double:
			#
			#gravity = -jump_strength
			#jump_double = false
			
		if(jump_single): action_jump()

# Handle gravity
func handle_gravity(delta):
	
	gravity += 20 * delta
	
	if gravity > 0 and is_on_floor():
		
		jump_single = true
		gravity = 0

# Jumping
func action_jump():
	
	gravity = -jump_strength
	
	jump_single = false;
	#jump_double = true;

# Add or Remove Health from Actor
func health_manager(value : int, is_damage : bool):
	#Could I somehow do this on the input field? Either way, ensure health value is always a positive.
	abs(value)
	
	if is_damage:
		health -= value
	else:
		health += value
	
	health_updated.emit(health) # Update health on HUD
	
	if health < 0:
		get_tree().reload_current_scene() # Reset when out of health

# Manage Ammo
func calculate_ammo(ammo_id, ammo_amount):
	if ammo_types.has(ammo_id):
		ammo_types[ammo_id] += ammo_amount
		
	if ammo_types[ammo_id] < 0:
		ammo_types[ammo_id] = 0
		
	if ammo_types[ammo_id] > ammo_types_max[ammo_id]:
		ammo_types[ammo_id] = ammo_types_max[ammo_id]
	
	#If our current weapon happens to use null ammo, avoid updating HUD until next time.
	if container.weapon.ammo_type != "ammo_null": 
		ammo_updated.emit(ammo_types.get(container.weapon.ammo_type))
	print( "Ammo is now: " + str( ammo_types.get(ammo_id) ) )

# Detect item pickups and act accordingly
func _on_pickup_detected(pickup_actor, pickup_data):
	#Syntactic Sugar
	var is_ammo : bool = pickup_data.drop_ammo
	var is_weapon : bool = pickup_data.drop_weapon
	var is_health : bool = pickup_data.drop_health
	
	#If the player can't obtain anything useful from this pickup item, deny it.
	var accepted_pickup : bool = false
	
	if is_ammo:
		#TODO: Don't give ammo if full.
		if self.ammo_types.get(pickup_data.ammo_type) < self.ammo_types_max.get(pickup_data.ammo_type):
			calculate_ammo(pickup_data.ammo_type, pickup_data.ammo_amount)
			accepted_pickup = true
			
	if is_health:
		if health < max_health:
			health += pickup_data.health_amount
			health_updated.emit(health) #TODO: Replace with manager later
			accepted_pickup = true
			
	if is_weapon:
		if container.weapons.has(pickup_data.weapon_id): #If we already own this weapon
			#If we have less than maximum ammo, of the ammo type defined for this pickup's ammo type.
				if self.ammo_types.get(pickup_data.ammo_type) < ammo_types_max.get(pickup_data.weapon_id.ammo_type):
					calculate_ammo(pickup_data.ammo_type, pickup_data.weapon_pickup_ammo)
					accepted_pickup = true
				else:
					print("YOU GET NOTHING. GOOD DAY SIR.")
					
		else: #All good to give weapon pickup proper
			container.weapons.append(pickup_data.weapon_id)
			#TODO: Change weapon to new pickup ID. Need to get its position in the weapon array.
			#initiate_change_weapon(pickup_data.weapon_id)
			accepted_pickup = true
			print("gave weapon with ID of: " + str(pickup_data.weapon_id))
			
	if accepted_pickup:
		pickup_actor.emit_signal("pickup_finish")
		Audio.play(pickup_data.sound_pickup)
