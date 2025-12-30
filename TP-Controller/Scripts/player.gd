class_name Player extends CharacterBody3D


@export var cam_sens = 0.1
@export var playerSpeed = 8.0
@export var lerp_speed = 10.0

var direction = Vector3.ZERO

const JUMP_VELOCITY = 4.5

@onready var visuals: Node3D = $playerVisuals
@onready var camera_mount: Node3D = $cameraMount
@onready var camera: Camera3D = $cameraMount/cameraSpringarm/camera


func camera_controls(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x) * cam_sens)
		visuals.rotate_y(deg_to_rad(event.relative.x) * cam_sens)
		camera_mount.rotate_x(deg_to_rad( -event.relative.y) * cam_sens)
		camera_mount.rotation.x = clamp(camera_mount.rotation.x, deg_to_rad(-70), deg_to_rad(15))

func _input(event: InputEvent) -> void:
	camera_controls(event)

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("a", "d", "w", "s")
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*lerp_speed)
	if direction:
		
		visuals.look_at(position + direction)
		velocity.x = direction.x * playerSpeed
		velocity.z = direction.z * playerSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, playerSpeed)
		velocity.z = move_toward(velocity.z, 0, playerSpeed)

	move_and_slide()
