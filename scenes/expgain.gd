extends HBoxContainer
class_name XpContainer

signal exp_finished
#Nodes
@onready var expBar : TextureProgressBar = $PanelContainer/ExpMargin/HC/expBar
@onready var expText : Control = $PanelContainer/ExpMargin/HC/expL
var tween : Tween
#exp variables
var growExp : bool = false
var expLimit : int = 0
var expGrowSpeed : float = 1
var expAdded : int = 0
var lvlResults : Dictionary = {}
enum DISPLAY_PHASE {IDLE, EXP_GAIN, EXP_DONE, LEVELUP_REVEAL, LEVELUP_DONE}
var display_phase := DISPLAY_PHASE.IDLE
var pending_levelup_report : Dictionary = {}
var pending_levelup_name := ""
var levelup_reveal_queue : Array[String] = []
var final_exp_target := 0


func _ready():
	SignalTower.prompt_accepted.connect(self.animation_skip)


func animation_skip():
	if !self.visible:
		return
	match display_phase:
		DISPLAY_PHASE.EXP_GAIN:
			_finish_exp_stage()
		DISPLAY_PHASE.EXP_DONE:
			if _has_levelup_report():
				_start_levelup_stage()
			else:
				_finish_display()
		DISPLAY_PHASE.LEVELUP_REVEAL:
			_finish_levelup_stage()
		DISPLAY_PHASE.LEVELUP_DONE:
			_finish_display()
		_:
			_finish_display()

func init_exp_display(oldExp, expSteps, results, unitPrt, unitName):
	var portrait = $MC/MC/UnitPrt
	var texture : CompressedTexture2D
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	if ResourceLoader.exists(unitPrt):
		texture = load(unitPrt)
		portrait.set_texture(texture)
	expBar.value = oldExp
	expText.set_text(str(expBar.value))
	final_exp_target = oldExp if expSteps.is_empty() else int(expSteps[-1])
	$PanelContainer.visible = true
	_toggle_exp_margin(true)
	$PanelContainer/LvUpMargin.visible = false
	growExp = true
	lvlResults = results
	pending_levelup_report = results
	pending_levelup_name = unitName
	display_phase = DISPLAY_PHASE.EXP_GAIN
	for expStep in expSteps:
		tween.tween_method(_increase_exp, oldExp, expStep, 0.5).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(_on_exp_stage_complete)
	
func _increase_exp(expStep):
	expBar.value = expStep
	expText.text = str(expStep)
	
func _display_levelup(report, unitName): #requires actual level up display
	var increases := {}
	display_phase = DISPLAY_PHASE.LEVELUP_REVEAL
	levelup_reveal_queue.clear()
	tween.tween_method(_toggle_lv_panel, true, false, 0.3).set_trans(Tween.TRANS_LINEAR)
	tween.tween_method(_toggle_exp_margin, true, false, 0.1).set_trans(Tween.TRANS_LINEAR)
	tween.tween_method(_toggle_lv_margin.bind(report, unitName), false, true, 0.1).set_trans(Tween.TRANS_LINEAR)
	tween.tween_method(_toggle_lv_panel, false, true, 0.3).set_trans(Tween.TRANS_LINEAR)
	
	for stat in report.Results.keys():
		if report.Results[stat] > 0:
			increases[stat] = report.Results[stat]

	var levels_gained := int(report.get("Levels", 0))
	if levels_gained > 0:
		levelup_reveal_queue.append("LVL")
		tween.tween_callback(_increase_level.bind(report))
		tween.tween_interval(0.4)

	if increases.is_empty():
		_dead_level()
		tween.tween_interval(2.0)
	else:
		for stat in increases.keys():
			levelup_reveal_queue.append(stat)
			tween.tween_callback(_increase_specific_stat.bind(stat, report, increases))
			tween.tween_interval(0.35)
	tween.tween_callback(_on_levelup_stage_complete)
	
func _toggle_lv_panel(status):
	$PanelContainer.visible = status
		
func _toggle_exp_margin(status):
	$PanelContainer/ExpMargin.visible = status

func _toggle_lv_margin(status, results, unitName):
	var oldStats = results.OldStats
	$PanelContainer/LvUpMargin/Vbox/Header/UnitName.text = unitName
	$PanelContainer/LvUpMargin/Vbox/Header/UnitLevel.text = str(oldStats.LVL)
	$PanelContainer/LvUpMargin/Vbox/HPCmpBox/UnitHp.text = str(oldStats.Life)
	$PanelContainer/LvUpMargin/Vbox/HPCmpBox/UnitCmp.text = str(oldStats.Comp)
	$PanelContainer/LvUpMargin/Vbox/Stats/UnitStr.text = str(oldStats.Pwr)
	$PanelContainer/LvUpMargin/Vbox/Stats/UnitMag.text = str(oldStats.Mag)
	$PanelContainer/LvUpMargin/Vbox/Stats/UnitEle.text = str(oldStats.Eleg)
	$PanelContainer/LvUpMargin/Vbox/Stats/UnitCele.text = str(oldStats.Cele)
	$PanelContainer/LvUpMargin/Vbox/Stats/UnitBar.text = str(oldStats.Def)
	$PanelContainer/LvUpMargin/Vbox/Stats/UnitCha.text = str(oldStats.Cha)
	$PanelContainer/LvUpMargin/Vbox/Header/Increase.text = ""
	$PanelContainer/LvUpMargin/Vbox/HPCmpBox/IncreaseHP.text = ""
	$PanelContainer/LvUpMargin/Vbox/HPCmpBox/IncreaseCmp.text = ""
	$PanelContainer/LvUpMargin/Vbox/Stats/Increase.text = ""
	$PanelContainer/LvUpMargin/Vbox/Stats/Increase2.text = ""
	$PanelContainer/LvUpMargin/Vbox/Stats/Increase3.text = ""
	$PanelContainer/LvUpMargin/Vbox/Stats/Increase4.text = ""
	$PanelContainer/LvUpMargin/Vbox/Stats/Increase5.text = ""
	$PanelContainer/LvUpMargin/Vbox/Stats/Increase6.text = ""
	$PanelContainer/LvUpMargin.visible = status
	
	
func _increase_level(report):
	var levels_gained := int(report.get("Levels", 0))
	if levels_gained <= 0:
		return
	var old_level := int(report.OldStats.get("LVL", 0))
	$PanelContainer/LvUpMargin/Vbox/Header/UnitLevel.text = str(old_level + levels_gained)
	$PanelContainer/LvUpMargin/Vbox/Header/Increase.text = ("+" + str(levels_gained))


func _increase_specific_stat(stat, report, increases):
	if stat == null or not report.OldStats.has(stat) or not increases.has(stat):
		return
	var statUp :int= report.OldStats[stat] + increases[stat]
	
	match stat:
		"Life":
			$PanelContainer/LvUpMargin/Vbox/HPCmpBox/UnitHp.text = str(statUp)
			$PanelContainer/LvUpMargin/Vbox/HPCmpBox/IncreaseHP.text = ("+" + str(increases[stat]))
		"Comp":
			$PanelContainer/LvUpMargin/Vbox/HPCmpBox/UnitCmp.text = str(statUp)
			$PanelContainer/LvUpMargin/Vbox/HPCmpBox/IncreaseCmp.text = ("+" + str(increases[stat]))
		"Pwr":
			$PanelContainer/LvUpMargin/Vbox/Stats/UnitStr.text = str(statUp)
			$PanelContainer/LvUpMargin/Vbox/Stats/Increase.text = ("+" + str(increases[stat]))
		"Mag":
			$PanelContainer/LvUpMargin/Vbox/Stats/UnitMag.text = str(statUp)
			$PanelContainer/LvUpMargin/Vbox/Stats/Increase2.text = ("+" + str(increases[stat]))
		"Eleg":
			$PanelContainer/LvUpMargin/Vbox/Stats/UnitEle.text = str(statUp)
			$PanelContainer/LvUpMargin/Vbox/Stats/Increase3.text = ("+" + str(increases[stat]))
		"Cele":
			$PanelContainer/LvUpMargin/Vbox/Stats/UnitCele.text = str(statUp)
			$PanelContainer/LvUpMargin/Vbox/Stats/Increase4.text = ("+" + str(increases[stat]))
		"Def":
			$PanelContainer/LvUpMargin/Vbox/Stats/UnitBar.text = str(statUp)
			$PanelContainer/LvUpMargin/Vbox/Stats/Increase5.text = ("+" + str(increases[stat]))
		"Cha":
			$PanelContainer/LvUpMargin/Vbox/Stats/UnitCha.text = str(statUp)
			$PanelContainer/LvUpMargin/Vbox/Stats/Increase6.text = ("+" + str(increases[stat]))


func _dead_level():
	pass


func _on_exp_stage_complete():
	growExp = false
	display_phase = DISPLAY_PHASE.EXP_DONE
	if _has_levelup_report():
		_start_levelup_stage()
	else:
		_finish_display()


func _on_levelup_stage_complete():
	display_phase = DISPLAY_PHASE.LEVELUP_DONE


func _start_levelup_stage():
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	_display_levelup(pending_levelup_report, pending_levelup_name)


func _finish_exp_stage():
	if tween:
		tween.custom_step(10000)
		tween.kill()
	growExp = false
	display_phase = DISPLAY_PHASE.EXP_DONE
	expBar.value = final_exp_target
	expText.text = str(final_exp_target)
	if _has_levelup_report():
		_start_levelup_stage()
	else:
		_finish_display()


func _finish_levelup_stage():
	if tween:
		tween.custom_step(10000)
		tween.kill()
	if int(pending_levelup_report.get("Levels", 0)) > 0:
		_increase_level(pending_levelup_report)
	var increases := {}
	for stat in pending_levelup_report.get("Results", {}).keys():
		if pending_levelup_report.Results[stat] > 0:
			increases[stat] = pending_levelup_report.Results[stat]
	for stat in increases.keys():
		_increase_specific_stat(stat, pending_levelup_report, increases)
	display_phase = DISPLAY_PHASE.LEVELUP_DONE


func _has_levelup_report() -> bool:
	return pending_levelup_report != null and int(pending_levelup_report.get("Levels", 0)) > 0


func _finish_display():
	self.visible = false
	display_phase = DISPLAY_PHASE.IDLE
	pending_levelup_report = {}
	pending_levelup_name = ""
	levelup_reveal_queue.clear()
	final_exp_target = 0
	emit_signal("exp_finished")
	
func toggle_visibility():
	self.visible = !self.visible
