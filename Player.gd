extends KinematicBody2D

var bullet = preload("res://Bullet.tscn")
var speed = 300

func _physics_process(_delta):
	look_at(get_global_mouse_position())
	var velocity = Vector2.ZERO
	
	var mouse_distance = (get_global_mouse_position() - position).length()

	if Input.is_action_pressed("up") and mouse_distance > 20:
		velocity.x += 1
	if Input.is_action_pressed("down") and mouse_distance > 20:
		velocity.x -= 1

	velocity = velocity.normalized()
	velocity *= speed
	velocity = velocity.rotated(rotation)

	velocity = move_and_slide(velocity)

	if Input.is_action_just_pressed("shoot"):
		shoot()

func shoot():
	var bullet_instance = bullet.instance()

	bullet_instance.position = $BulletSpawnPosition.get_global_position()
	bullet_instance.rotation_degrees = rotation_degrees
	bullet_instance.apply_impulse(
		Vector2.ZERO,
		Vector2(1000, 0).rotated(rotation)
	)

	get_tree().get_root().add_child(bullet_instance)

func _on_Hitbox_body_entered(body):
	if body.is_in_group("enemies"):
		get_tree().reload_current_scene()
