extends KinematicBody2D

const SPEED = 100

onready var player = get_tree().get_current_scene().get_node("Player")

var lives = 3
var alive = true

func _physics_process(delta):
	if alive:
		look_at(player.position)

		var direction = (player.position - position).normalized()
		move_and_slide(direction * SPEED)

func _on_Hitbox_body_entered(body):
	if body.is_in_group("bullets"):
		lives -= 1
		body.queue_free()

	if lives == 0:
		alive = false
		$Sprite.visible = false
		$LightOccluder2D.visible = false
		$NameLabel.visible = false

		$Explosion.visible = true
		$Explosion.play("explode")

func set_name(name):
	$NameLabel.text = name

func _on_Explosion_animation_finished():
	queue_free()
