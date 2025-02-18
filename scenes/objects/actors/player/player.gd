#TODO: Type all variables. Better sanity / safety and slightly better performance.
extends CharacterBody3D
class_name DM23Player

#region Node References
@onready var camera = $Neck/Head/Camera
@onready var sound_footsteps = $SoundFootsteps

@onready var neck: Node3D = $Neck
@onready var head: Node3D = $Neck/Head

@export var footsteps: AudioStreamPlayer3D
@export var jump_or_land: AudioStreamPlayer3D
@export var misc_sound: AudioStreamPlayer3D

#endregion

#region Variables
@export_subgroup("Properties")
@export var movement_speed = 5
@export var jump_strength = 8
@export var health_component: HealthComponent
@export var weapon_manager: WeaponManagerComponent

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

@export var CAMERA_SMOOTHING := 18.0	# Amount of camera smoothing.
@export var MAX_STEP_UP := 0.5			# Maximum height in meters the player can step up.
@export var MAX_STEP_DOWN := -0.5		# Maximum height in meters the player can step down.

var is_grounded := true					# If player is grounded this frame
var was_grounded := true				# If player was grounded last frame

var vertical := Vector3(0, 1, 0)		# Shortcut for converting vectors to vertical
var horizontal := Vector3(1, 0, 1)		# Shortcut for converting vectors to horizontal

var wish_dir := Vector3.ZERO			# Player input (WASD) direction

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
#endregion

# FUNCTIONS

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta):
	handle_mouse_controls(delta)

func _physics_process(delta):
	# Lock player collider rotation
	$Collider.global_rotation = Vector3.ZERO

	# Update player state
	was_grounded = is_grounded

	if is_on_floor():
		is_grounded = true
	else:
		is_grounded = false
	
	# Handle functions
	
	handle_controls(delta)
	handle_gravity(delta)
	
	# Movement

	var applied_velocity: Vector3
	
	movement_velocity = transform.basis * movement_velocity # Move forward
	
	#TODO: Keep an eye on how this sall interacts with the stair logic
	#TODO: Consider removing the lerp once stair stepping?
	applied_velocity = velocity.lerp(movement_velocity, delta * 10)
	applied_velocity.y = -gravity
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	wish_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
	#velocity.x = wish_dir.x * movement_speed
	#velocity.z = wish_dir.z * movement_speed
	#velocity.y = -gravity
	
	
	velocity = applied_velocity
	
	
	#Credit to kelpysama & JKWall
	# Stair step up
	stair_step_up()
	
	# Move
	move_and_slide()
	
	# Stair step down
	stair_step_down()

	# Smooth Camera
	smooth_camera_jitter(delta)
	
	
	# Rotation
	
	camera.rotation.z = lerp_angle(camera.rotation.z, -input_mouse.x * 25 * delta, delta * 5)	
	camera.rotation.x = lerp_angle(camera.rotation.x, rotation_target.x, delta * 25)
	
	rotation.y = lerp_angle(rotation.y, rotation_target.y, delta * 25)
	
	#Weapon Container Rotation
	
	weapon_manager.position = lerp(weapon_manager.position, weapon_manager.container_offset - (basis.inverse() * applied_velocity / 30), delta * 10)
	
	# Movement sound
	
	sound_footsteps.stream_paused = true
	
	if is_on_floor():
		if abs(velocity.x) > 1 or abs(velocity.z) > 1:
			sound_footsteps.stream_paused = false
	
	# Landing after jump or falling
	
	camera.position.y = lerp(camera.position.y, 0.0, delta * 5)
	
	#TODO: Velocity minimum for landing sound.
	if is_on_floor() and gravity > 1 and !previously_floored: # Landed
		
		jump_or_land.set_stream( load("sounds/actors/player/movement/land.ogg") )
		jump_or_land.play()
		camera.position.y = -0.1
	
	previously_floored = is_on_floor()
	
	# Falling/respawning
	
	if position.y < -10:
		get_tree().reload_current_scene()

#region Stair Logic
# Function: Handle walking down stairs
func stair_step_down():
	if is_grounded:
		return

	# If we're falling from a step
	if velocity.y <= 0 and was_grounded:
		#_debug_stair_step_down("SSD_ENTER", null)													## DEBUG

		# Initialize body test variables
		var body_test_result = PhysicsTestMotionResult3D.new()
		var body_test_params = PhysicsTestMotionParameters3D.new()

		body_test_params.from = self.global_transform			## We get the player's current global_transform
		body_test_params.motion = Vector3(0, MAX_STEP_DOWN, 0)	## We project the player downward

		if PhysicsServer3D.body_test_motion(self.get_rid(), body_test_params, body_test_result):
			# Enters if a collision is detected by body_test_motion
			# Get distance to step and move player downward by that much
			position.y += body_test_result.get_travel().y
			apply_floor_snap()
			is_grounded = true
			#_debug_stair_step_down("SSD_APPLIED", body_test_result.get_travel().y)					## DEBUG

# Function: Handle walking up stairs
func stair_step_up():
	if wish_dir == Vector3.ZERO:
		return

	#_debug_stair_step_up("SSU_ENTER", null)															## DEBUG

	# 0. Initialize testing variables
	var body_test_params = PhysicsTestMotionParameters3D.new()
	var body_test_result = PhysicsTestMotionResult3D.new()

	var test_transform = global_transform				## Storing current global_transform for testing
	var distance = wish_dir * 0.1						## Distance forward we want to check
	body_test_params.from = self.global_transform		## Self as origin point
	body_test_params.motion = distance					## Go forward by current distance

	#_debug_stair_step_up("SSU_TEST_POS", test_transform)											## DEBUG

	# Pre-check: Are we colliding?
	if !PhysicsServer3D.body_test_motion(self.get_rid(), body_test_params, body_test_result):
		#_debug_stair_step_up("SSU_EXIT_1", null)													## DEBUG

		## If we don't collide, return
		return

	# 1. Move test_transform to collision location
	var remainder = body_test_result.get_remainder()							## Get remainder from collision
	test_transform = test_transform.translated(body_test_result.get_travel())	## Move test_transform by distance traveled before collision

	#_debug_stair_step_up("SSU_REMAINING", remainder)												## DEBUG
	#_debug_stair_step_up("SSU_TEST_POS", test_transform)											## DEBUG

	# 2. Move test_transform up to ceiling (if any)
	var step_up = MAX_STEP_UP * vertical
	body_test_params.from = test_transform
	body_test_params.motion = step_up
	PhysicsServer3D.body_test_motion(self.get_rid(), body_test_params, body_test_result)
	test_transform = test_transform.translated(body_test_result.get_travel())

	#_debug_stair_step_up("SSU_TEST_POS", test_transform)											## DEBUG

	# 3. Move test_transform forward by remaining distance
	body_test_params.from = test_transform
	body_test_params.motion = remainder
	PhysicsServer3D.body_test_motion(self.get_rid(), body_test_params, body_test_result)
	test_transform = test_transform.translated(body_test_result.get_travel())

	#_debug_stair_step_up("SSU_TEST_POS", test_transform)											## DEBUG

	# 3.5 Project remaining along wall normal (if any)
	## So you can walk into wall and up a step
	if body_test_result.get_collision_count() != 0:
		remainder = body_test_result.get_remainder().length()

		### Uh, there may be a better way to calculate this in Godot.
		var wall_normal = body_test_result.get_collision_normal()
		var dot_div_mag = wish_dir.dot(wall_normal) / (wall_normal * wall_normal).length()
		var projected_vector = (wish_dir - dot_div_mag * wall_normal).normalized()

		body_test_params.from = test_transform
		body_test_params.motion = remainder * projected_vector
		PhysicsServer3D.body_test_motion(self.get_rid(), body_test_params, body_test_result)
		test_transform = test_transform.translated(body_test_result.get_travel())

		#_debug_stair_step_up("SSU_TEST_POS", test_transform)										## DEBUG

	# 4. Move test_transform down onto step
	body_test_params.from = test_transform
	body_test_params.motion = MAX_STEP_UP * -vertical

	# Return if no collision
	if !PhysicsServer3D.body_test_motion(self.get_rid(), body_test_params, body_test_result):
		#_debug_stair_step_up("SSU_EXIT_2", null)													## DEBUG

		return

	test_transform = test_transform.translated(body_test_result.get_travel())
	#_debug_stair_step_up("SSU_TEST_POS", test_transform)											## DEBUG

	# 5. Check floor normal for un-walkable slope
	var surface_normal = body_test_result.get_collision_normal()
	print("SSU: Surface check: ", snappedf(surface_normal.angle_to(vertical), 0.001), " vs ", floor_max_angle)#!
	if (snappedf(surface_normal.angle_to(vertical), 0.001) > floor_max_angle):
		#_debug_stair_step_up("SSU_EXIT_3", null)													## DEBUG

		return
	print("SSU: Walkable")#!
	#_debug_stair_step_up("SSU_TEST_POS", test_transform)											## DEBUG

	# 6. Move player up
	var global_pos = global_position
	var step_up_dist = test_transform.origin.y - global_pos.y
	#_debug_stair_step_up("SSU_APPLIED", step_up_dist)												## DEBUG

	velocity.y = 0
	global_pos.y = test_transform.origin.y
	global_position = global_pos

# Function: Smooth camera jitter
#TODO: adjust my player controller to have a neck too
func smooth_camera_jitter(delta):
	head.global_position.x = neck.global_position.x
	head.global_position.y = lerpf(head.global_position.y, neck.global_position.y, CAMERA_SMOOTHING * delta)
	head.global_position.z = neck.global_position.z

	# Limit how far camera can lag behind its desired position
	head.global_position.y = clampf(head.global_position.y,
										-neck.global_position.y - 1,
										neck.global_position.y + 1)
#endregion

func _input(event):
	if event is InputEventMouseMotion and mouse_captured:
		
		input_mouse = event.relative / mouse_sensitivity
		
		rotation_target.y -= event.relative.x / mouse_sensitivity
		rotation_target.x -= event.relative.y / mouse_sensitivity

# Handle Mouse Control
func handle_mouse_controls(_delta):
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
			jump_or_land.set_stream( load(jump_sound.pick_random()) )
			jump_or_land.play()
			
		#if jump_double:
			#
			#gravity = -jump_strength
			#jump_double = false
			
		if(jump_single): action_jump()

# Handle gravity
func handle_gravity(delta):
	
	if !is_on_floor():
		gravity += 20 * delta
		#velocity.y -= gravity * delta	
	
	
	if gravity > 0 and is_on_floor():
		
		jump_single = true
		gravity = 0

# Jumping
func action_jump():
	
	gravity = -jump_strength
	
	jump_single = false;
	#jump_double = true;

# Manage Ammo
func calculate_ammo(ammo_id, ammo_amount):
	if ammo_types.has(ammo_id):
		ammo_types[ammo_id] += ammo_amount
		
	if ammo_types[ammo_id] < 0:
		ammo_types[ammo_id] = 0
		
	if ammo_types[ammo_id] > ammo_types_max[ammo_id]:
		ammo_types[ammo_id] = ammo_types_max[ammo_id]
	
	#If our current weapon happens to use null ammo, avoid updating HUD until next time.
	if weapon_manager.weapon.ammo_type != "ammo_null": 
		ammo_updated.emit(ammo_types.get(weapon_manager.weapon.ammo_type))
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
		if health_component.health < health_component.max_health:
			health_component.give_health(pickup_data.health_amount)
			accepted_pickup = true
			
	if is_weapon:
		if weapon_manager.weapons.has(pickup_data.weapon_id): #If we already own this weapon
			#If we have less than maximum ammo, of the ammo type defined for this pickup's ammo type.
				if self.ammo_types.get(pickup_data.ammo_type) < ammo_types_max.get(pickup_data.weapon_id.ammo_type):
					calculate_ammo(pickup_data.ammo_type, pickup_data.weapon_pickup_ammo)
					accepted_pickup = true
				else:
					print("YOU GET NOTHING. GOOD DAY SIR.")
					
		else: #All good to give weapon pickup proper
			weapon_manager.weapons.append(pickup_data.weapon_id)
			#TODO: Change weapon to new pickup ID. Need to get its position in the weapon array.
			#initiate_change_weapon(pickup_data.weapon_id)
			accepted_pickup = true
			get_tree().call_group("GUI", "update_pickup_box", pickup_data.name)
			print("Gave Weapon Pickup of Name: " + str(pickup_data.name))
			
	if accepted_pickup:
		pickup_actor.emit_signal("pickup_finish")
		misc_sound.set_stream( load(pickup_data.sound_pickup) )
		misc_sound.play()
