extends Node
class_name Action

enum ACTION_TYPE{MOVE,ATTACK,SKILL_HOSTILE,SKILL_FRIENDLY,WAIT,TRADE,USE_ITEM,CANTO,TIME_WARP,}
var unit_id:String
var type:ACTION_TYPE
var from_cell:Vector2i
var target_cell:Vector2i
var target_unit_id:String
var item:Item
var skill:Skill
