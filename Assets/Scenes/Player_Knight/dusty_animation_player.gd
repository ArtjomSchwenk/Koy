extends AnimationPlayer

signal left_foot_run_hit_ground();
signal right_foot_run_hit_ground();

func trigger_left_foot_run_hit_ground():
	left_foot_run_hit_ground.emit();
	
func trigger_right_foot_run_hit_ground():
	right_foot_run_hit_ground.emit();

func _on_left_foot_run_hit_ground():
	$"../Rig_Medium/Skeleton3D/Foot_L/DustCloud".emitting = true;
	var players = $"../Rig_Medium/Skeleton3D/Foot_L".get_children()
	var audio_players := []

	for child in players:
		if child is AudioStreamPlayer3D:
			audio_players.append(child)

	if audio_players.size() > 0:
		audio_players.pick_random().play()

func _on_right_foot_run_hit_ground():
	$"../Rig_Medium/Skeleton3D/Foot_R/DustCloud".emitting = true;
	var players = $"../Rig_Medium/Skeleton3D/Foot_R".get_children()
	var audio_players := []

	for child in players:
		if child is AudioStreamPlayer3D:
			audio_players.append(child)

	if audio_players.size() > 0:
		audio_players.pick_random().play()
