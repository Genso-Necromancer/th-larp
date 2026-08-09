extends Node
class_name Action

# Small payload object for simulated choices. Keep this dumb: legality and
# scoring live elsewhere, while Action just carries actor/source/target data.
enum ACTION_TYPE{MOVE,ATTACK,SKILL_HOSTILE,SKILL_FRIENDLY,WAIT,TRADE,USE_ITEM,CANTO,DOOR,CHEST,WALL,TIME_WARP,}
var unit_id:String
var type:ACTION_TYPE
var from_cell:Vector2i
var target_cell:Vector2i
var target_unit_id:String
var moved_hexes:int = 0
# Stored as sim-safe dictionaries rather than live resources.
var item
var skill
