extends HBoxContainer

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


func _ready():
	SignalTower.prompt_accepted.connect(self.animation_skip)


func animation_skip():
	if !self.visible:
		return
	elif tween and growExp:
		tween.custom_step(10000)
		tween.kill()
		growExp = false
	else:
		self.visible = false
		emit_signal("exp_finished")

func init_exp_display(oldExp, expSteps, results, unitPrt, unitName):
	var portrait = $MC/MC/UnitPrt
	var isLeveled = 0
	tween = get_tree().create_tween()
	
	portrait.set_texture(unitPrt)
	expBar.value = oldExp
	expText.set_text(str(expBar.value))
#	tween.tween_property(expBar, "value", finalExp, 1)
	growExp = true
	lvlResults = results
	for expStep in expSteps:
		tween.tween_method(_increase_exp, oldExp, expStep, 0.5).set_trans(Tween.TRANS_LINEAR)
		isLeveled += 1
	if isLeveled >= 2:
		_display_levelup(results, unitName)
	tween.tween_callback(_kill_tween)
	
func _increase_exp(expStep):
	expBar.value = expStep
	expText.text = str(expStep)
	
func _display_levelup(report, unitName): #requires actual level up display
	var stats = report.Results.keys()
	var increases = {}
	tween.tween_method(_toggle_lv_panel, true, false, 0.3).set_trans(Tween.TRANS_LINEAR) #Toggle off
	tween.tween_method(_toggle_exp_margin, true, false, 0.1).set_trans(Tween.TRANS_LINEAR)#Toggle off
	tween.tween_method(_toggle_lv_margin.bind(report, unitName), false, true, 0.1).set_trans(Tween.TRANS_LINEAR)#Toggle off
	tween.tween_method(_toggle_lv_panel, false, true, 0.3).set_trans(Tween.TRANS_LINEAR) #Toggle On
	
	for stat in stats:
		if report.Results[stat] > 0:
			increases[stat] = report.Results[stat]
	
	tween.tween_method(_increase_stat.bind(report, increases), 0, (increases.size() - 1), 2).set_trans(Tween.TRANS_LINEAR)
	
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
	
	
func _increase_stat(index, report, increases):
	var stats = increases.keys()
	var stat = stats[index]
	var statUp = report.OldStats[stat] + increases[stat]
	
	match stat:
		"LVL":
			$PanelContainer/LvUpMargin/Vbox/Header/UnitLevel.text = str(statUp)
			$PanelContainer/LvUpMargin/Vbox/Header/Increase.text = ("+" + str(increases[stat]))
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

func _kill_tween():
	growExp = false
	tween.kill()
	
func toggle_visibility():
	self.visible = !self.visible
