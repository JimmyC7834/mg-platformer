extends Node

const PROJECTILE = preload("res://projectile.tscn")

enum TYPE {
    DEFAULT,
}

func spawn_projectile(type: TYPE, position: Vector2, velocity: Vector2):
    var p: Projectile = PROJECTILE.instantiate()
    p.velocity = velocity
    p.global_position = position
    add_child(p)
