extends Area2D

func _on_SafeArea_body_entered(body):
	body.safe_areas.append(get_instance_id())


func _on_SafeArea_body_exited(body):
	body.safe_areas.erase(get_instance_id())
