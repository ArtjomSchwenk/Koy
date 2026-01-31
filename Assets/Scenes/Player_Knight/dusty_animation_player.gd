extends AnimationPlayer

signal left_foot_run_hit_ground();
signal right_foot_run_hit_ground();

func trigger_left_foot_run_hit_ground():
	left_foot_run_hit_ground.emit();
	
func trigger_right_foot_run_hit_ground():
	right_foot_run_hit_ground.emit();

func _on_left_foot_run_hit_ground():
	$"../Rig_Medium/Skeleton3D/Foot_L/DustCloud".emitting = true;

func _on_right_foot_run_hit_ground():
	$"../Rig_Medium/Skeleton3D/Foot_R/DustCloud".emitting = true;
