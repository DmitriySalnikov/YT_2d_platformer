extends Node2D

export var HitSplashParticles : PackedScene

onready var rc := $RayCast2D

func shoot(exception_node : Node2D, dmg : float, max_dist : float):
	rc.cast_to = Vector2(max_dist, 0)
	rc.add_exception(exception_node)
	rc.force_raycast_update()
	
	var collider = rc.get_collider()
	
	if collider:
		if collider is StickmanCharacter:
			var tmp_splash : Particles2D = HitSplashParticles.instance()
			get_parent().add_child(tmp_splash)
			tmp_splash.rotation = rc.get_collision_normal().angle() + PI
			tmp_splash.global_position = rc.get_collision_point() + Vector2(collider.capsule_collison.shape.radius, 0).rotated(tmp_splash.rotation)
			
			collider.health_comp.decrease_hp(dmg)
		$Line2D.points = [Vector2(), Vector2((rc.get_collision_point() - global_position).length(), 0)]
	else:
		$Line2D.points = [Vector2(), Vector2(max_dist,0)]
