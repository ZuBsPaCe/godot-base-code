class_name Runner
extends Reference

var aborted := false setget ,_aborted_get

var pause_mode := Node.PAUSE_MODE_PROCESS

var _timers := []
var _tweens := []
var _animation_players := []


signal proceed
		
	
func abort():
	aborted = true
	_clear()
	_emit_abort()
	
	
func create_timer(p_parent: Node, p_secs: float) -> Timer:
	assert(!aborted)
	assert(p_parent != null and is_instance_valid(p_parent))
	assert(pause_mode == Node.PAUSE_MODE_PROCESS or !p_parent.get_tree().paused)
	
	var timer = Timer.new()
	timer.pause_mode = pause_mode
	timer.wait_time = p_secs
	timer.one_shot = true
	timer.autostart = true
	
	timer.connect("timeout", self, "_timeout", [timer])
	
	p_parent.add_child(timer)
	_timers.append(timer)
	return timer
	
	
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# destructor logic
		for timer in _timers:
			if is_instance_valid(timer):
				timer.queue_free()


func create_tween(p_parent: Node) -> SceneTreeTween:
	assert(!aborted)
	assert(p_parent != null and is_instance_valid(p_parent))
	assert(pause_mode == Node.PAUSE_MODE_PROCESS or !p_parent.get_tree().paused)
	
	var tween := p_parent.create_tween().set_pause_mode(pause_mode)
	
	tween.connect("finished", self, "_finished", [tween])
	
	_tweens.append(tween)
	return tween


func play_anim(player: AnimationPlayer, anim: String) -> AnimationPlayer:
	assert(!aborted)
	assert(!_animation_players.has(player))
	assert(player.pause_mode == Node.PAUSE_MODE_PROCESS or !player.get_tree().paused)
	
	player.connect("animation_finished", self, "_animation_finished", [player])
	player.play(anim)	
	_animation_players.append(player)
	return player


func wait_for_anim(player: AnimationPlayer):
	assert(!aborted)
	assert(!_animation_players.has(player))
	assert(player.is_playing())
	assert(player.pause_mode == Node.PAUSE_MODE_PROCESS or !player.get_tree().paused)
	
	player.connect("animation_finished", self, "_animation_finished", [player])
	_animation_players.append(player)
	return player


func _aborted_get():
	return aborted
	

func _clear():
	for timer in _timers:
		if is_instance_valid(timer):
			timer.stop()
			timer.queue_free()
	_timers.clear()
	
	for tween in _tweens:
		if is_instance_valid(tween):
			tween.kill()
	_tweens.clear()
	
	for player in _animation_players:
		if is_instance_valid(player):
			player.stop()
	_animation_players.clear()

func _timeout(timer: Timer):
	timer.disconnect("timeout", self, "_timeout")
	_timers.erase(timer)
	timer.queue_free()
	emit_signal("proceed", true)
	
func _finished(tween: SceneTreeTween):
	tween.disconnect("finished", self, "_finished")
	_tweens.erase(tween)
	emit_signal("proceed", true)

func _animation_finished(_anim_name: String, player: AnimationPlayer):
	player.disconnect("animation_finished", self, "_animation_finished")
	_animation_players.erase(player)
	emit_signal("proceed", true)
	
func _emit_abort():
	emit_signal("proceed", false)
