class_name Player extends CharacterBody3D


# remove having multiple collision shapes and just change the shape of 1 coll shape 
#
# var shape = CylinderShape.new()
# shape.set_radius(new_radius)
# shape.set_height(new_height)
# $Spatial/CollisionShape.shape = shape


@export_category("Movement")
@export var standspeed :float  = 8.0
@export var crouchspeed :float = 4.0

@export_category("Transitions")
@export var lerp_speed :float= 10.0

@export_category("Camera")
@export var cam_sens :float= 0.1

@export_subgroup("Distance Transparency")
@export var cam_transp_amount:float = 0.8
@export var cam_transp_mindis:float = 1.8

@export_subgroup("Crouching")
@export var cam_pos_crouch :Vector3= Vector3(0.4,-0.5,0)
@export var cam_dist_crouch :float= 2.0

@export_subgroup("Standing")
@export var cam_pos_stand :Vector3= Vector3(0.15,0.2,0)
@export var cam_dist_stand :float= 4.0

var playerSpeed :float
var direction = Vector3.ZERO
var is_crouching:bool = false

const JUMP_VELOCITY :float= 4.5

@onready var visuals: Node3D = $playerVisuals

@onready var camera_mount: Node3D = $cameraMount
@onready var camera: Camera3D = $cameraMount/cameraSpringarm/camera
@onready var camera_springarm: SpringArm3D = $cameraMount/cameraSpringarm

@onready var player_standing_mesh: MeshInstance3D = $playerVisuals/player_standingMesh
@onready var player_crouching_mesh: MeshInstance3D = $playerVisuals/player_crouchingMesh
@onready var player_crouching_col: CollisionShape3D = $player_crouchingCol
@onready var player_standing_col: CollisionShape3D = $player_standingCol
@onready var uncrouch_checker: RayCast3D = $uncrouch_checker


func camera_controls(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x) * cam_sens)
		visuals.rotate_y(deg_to_rad(event.relative.x) * cam_sens)
		camera_mount.rotate_x(deg_to_rad( -event.relative.y) * cam_sens)
		camera_mount.rotation.x = clamp(camera_mount.rotation.x, deg_to_rad(-70), deg_to_rad(15))

func player_cam_transparency(delta):
	if snapped(camera_springarm.get_hit_length(),0.01) <= cam_transp_mindis:
		
		player_crouching_mesh.transparency = lerp(player_crouching_mesh.transparency,cam_transp_amount,delta*lerp_speed)
		player_standing_mesh.transparency = lerp(player_standing_mesh.transparency,cam_transp_amount,delta*lerp_speed)
	else:
		player_crouching_mesh.transparency = lerp(player_crouching_mesh.transparency,0.0,delta*lerp_speed)
		player_standing_mesh.transparency = lerp(player_standing_mesh.transparency,0.0,delta*lerp_speed)
	
func crouching(delta):
	if is_crouching:
		if is_on_floor():
			playerSpeed = crouchspeed
		
		camera_mount.position = lerp(camera_mount.position, cam_pos_crouch, delta*lerp_speed)
		camera_springarm.spring_length = lerp(camera_springarm.spring_length, cam_dist_crouch, delta*lerp_speed)
		
		player_crouching_col.disabled = false
		player_standing_col.disabled = true
		
		player_crouching_mesh.show()
		player_standing_mesh.hide()
	else:
		playerSpeed = standspeed
		
		camera_mount.position = lerp(camera_mount.position, cam_pos_stand, delta*lerp_speed)
		camera_springarm.spring_length = lerp(camera_springarm.spring_length, cam_dist_stand, delta*lerp_speed)
		player_crouching_col.disabled = true
		player_standing_col.disabled = false
		
		player_crouching_mesh.hide()
		player_standing_mesh.show()
	
	if Input.is_action_pressed("Crouch"):
		is_crouching = true
	
	if !uncrouch_checker.is_colliding():
		if is_crouching and !Input.is_action_pressed("Crouch"):
			is_crouching = false

func _input(event: InputEvent) -> void:
	camera_controls(event)
	if Input.is_action_pressed("show_cursor"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	crouching(delta)
	player_cam_transparency(delta)

func _physics_process(delta: float) -> void:
	
	$fpslabel.text = "fps: " + str(Engine.get_frames_per_second())
	
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backward")
	var movement := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*lerp_speed)
	if movement:
		visuals.look_at(position + movement)
	if is_on_floor():	
		if direction:
			velocity.x = direction.x * playerSpeed
			velocity.z = direction.z * playerSpeed
		else:
			velocity.x = lerp(velocity.x, 0.0, delta*5.0)
			velocity.z = lerp(velocity.x, 0.0, delta*5.0)
	else:
			velocity.x = lerp(velocity.x, direction.x * playerSpeed, delta*5.0)
			velocity.z = lerp(velocity.z, direction.z * playerSpeed, delta*5.0)
	
	move_and_slide()
