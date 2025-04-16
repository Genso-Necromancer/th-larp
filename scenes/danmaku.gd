extends Path2D
class_name Danmaku

signal danmaku_relocated
signal animation_completed
signal collision_detected


@onready var _pathFollow: DanmakuType = $DanmakuType
@onready var sprite : Sprite2D = _pathFollow.get_sprite2D()
@onready var _animPlayer :AnimationPlayer = _pathFollow.animPlayer

#var texture : = "res://sprites/danmaku/danmaku.png":
	#get:
		#return texture
	#set(value):
		#texture = value
		#_setsprite_texture(value)
var sfx
var move : int
var moveStyle : String
var texture : CompressedTexture2D
var activePath : Array
var pathPattern : Array
var patternStep := 0
var damage : int
var cmpDamage : int
var impactEffects : Array
var speed : int
var typeId : StringName
var dmkName : String
var master : Unit
var faction = Enums.FACTION_ID.ENEMY
var unitHit : Unit

var lastAnim : String
var hexMoved : int = 0
var cell := Vector2i.ZERO:
	set(value):
		cell = get_parent().cell_clamp(value)
		_set_cell_lbl(cell)
var originCell := Vector2i.ZERO
var isMoving := false
var lastGlbPosition := Vector2.ZERO
var directions := [
	"walk_left",
	"walk_up",
	"walk_right",
	"walk_down",
]
var facing : int = 0
var isPhasing := false
var hexDirect := [
	"Top-Left",
	"Top",
	"Top-Right",
	"Bottom-Right",
	"Bottom",
	"bottom-Left",
]


func _ready():
	#if get_parent().ground:
		#initialize_cell()
		
	#if not Engine.is_editor_hint():
		#curve = Curve2D.new()
	_signals()

func _process(delta):
	if isMoving:
		_process_motion(delta)


func initialize_cell():
	var coord = $Cell
	cell = get_parent().local_to_map(position)
	position = get_parent().map_to_local(cell)
	originCell = cell
	coord.set_text(str(cell))


func init_bullet(dmk_master:Unit):
	var dmk :DanmakuType = _pathFollow
	texture = dmk.sprite
	sfx = dmk.sfx
	move = dmk.move
	damage = dmk.damage
	cmpDamage = dmk.cmpDamage
	impactEffects = dmk.impact
	speed = dmk.speed
	for i in curve.point_count:
		pathPattern.append(curve.get_point_position(i))
	moveStyle = StringGetter.get_string(("danmaku_movetype_%s" % [curve.resource_name.to_lower()]))
	#isPhasing = dmk.IsPhasing
	typeId = dmk.type
	master = dmk_master
	dmkName = StringGetter.get_string(("danmaku_type_%s" % [typeId]))
	_pathFollow.set_loop(false)
	#fullPath = _fullPath


func _signals():
	var hitBox = _pathFollow.area2d
	if !_animPlayer.animation_finished.is_connected(self._on_animation_finished):
		_animPlayer.animation_finished.connect(self._on_animation_finished)
	hitBox.set_master(self)
	hitBox.area_entered.connect(self._on_area_entered)
	hitBox.area_exited.connect(self._on_area_exited)

func play_animation(animation):
	_animPlayer.play(animation)


func _on_animation_finished(anim):
	match anim:
		"Spawning": _animPlayer.play("Idle")
		"Collision": unitHit.danmaku_collision()
	emit_signal("animation_completed", anim, self)
	
func _set_cell_lbl(c):
	var lbl = $Cell
	lbl.set_text(str(c))
	
func _setsprite_texture(t : String):
	sprite.texture = load(t)

	
func set_facing(i):
	var pf2d = $DanamakuType
	
	#"TopRight","BottomRight","Bottom","BottomLeft","TopLeft","Top",
	var d := [6,0.2,1.59,3,3.3,4.72,]
	#var normie = d.normalized()
	#radian = int(directions.size() * (normie.rotated(PI / directions.size()).angle() + PI) / TAU)
	#print("[",radian,"]")
	#sprite.set_rotation(radian)
	facing = i
	pf2d.set_rotation(d[i])
	
	
	

func set_path(path):
	activePath = path
	#_pathFollow.set_rotates(true)
	_pathFollow.set_loop(false)
	#print(path)
	curve.add_point(Vector2.ZERO)
	for point in path:
		curve.add_point(get_parent().map_to_local(point) - position)


func start_move():
	_fill_path()
	isMoving = true


func _fill_path():
	while curve.get_point_count() <= move:
		curve.add_point(pathPattern[patternStep])
		patternStep += 1
	if patternStep >= pathPattern.size(): patternStep = 0


func _fade_out():
	pass


func _process_motion(delta):
	var directionsSize = directions.size()
	var current_move_vec 
	var norm_move_vec 
	var direction_id
	var prog = speed * delta
	prog = clamp(prog, 0, 1.0)
		
	lastGlbPosition = sprite.global_position
	_pathFollow.progress += prog
	current_move_vec = sprite.global_position - lastGlbPosition
	lastGlbPosition = sprite.global_position
	
	norm_move_vec = current_move_vec.normalized()
	direction_id = int(directionsSize * (norm_move_vec.rotated(PI / directionsSize).angle() + PI) / TAU)
	cell = get_parent().local_to_map(sprite.global_position)
	#_animPlayer.play(str(directions[direction_id]))
	#print(_pathFollow.progress_ratio)
	#print(_pathFollow.progress)
	
	if _pathFollow != null and _pathFollow.progress_ratio >= 1.0:
		#print("SHOULDN'T SEE BELOW 1.0 ",_pathFollow.progress_ratio)
		# Setting this value to 0.0 causes a Zero Length Interval error
		_pathFollow.progress = 0.00001
		lastGlbPosition = Vector2(0,0)
		
		position = get_parent().map_to_local(cell)
		curve.clear_points()
		stop_move()
		

func _on_area_entered(area):
	var unit : Unit = area.master
	if unit.FACTION_ID != faction:
		_collided(unit)
	print("Entered:",area.master)
	
func _on_area_exited(area):
	print("Exited:",area.master)

func stop_move():
	isMoving = false
	_update_cell()
	
func pause_move():
	isMoving = false
	
func _collided(unit):
	if activePath.has(unit.cell):
		var newPath = [unit.cell]
		isMoving = false
		unitHit = unit
		set_path(newPath)
		emit_signal("collision_detected", self)
	
func play_collide():
	isMoving = true
	apply_collision_effect()
	_animPlayer.play("Collision")

func apply_collision_effect():
	if damage: unitHit.apply_dmg(damage, master)
	if cmpDamage: unitHit.apply_composure(cmpDamage)
	#Effect application code: combat manager needs to be a singleton, or 
	#effect processing needs to be a seperate script that can be loaded seperately.
	#Currently too round-about to call effects for Danmaku

func _update_cell():
	emit_signal("danmaku_relocated", originCell, cell, self)
	originCell = cell
	
func relocate(newCell):
	var oldCell = cell
	var map = get_parent()
	position = map.map_to_local(newCell)
	cell = map.local_to_map(position)
	emit_signal("danmaku_relocated", oldCell, cell, self)
	originCell = cell
