extends Node

enum LANGUAGE {AMERICAN,}
enum UNIT_ID {Remilia, Sakuya, Patchy, China,}
enum FACTION_ID {ENEMY, PLAYER, NPC,}
enum MOVE_TYPE {FOOT, FLY,}
enum SPEC_ID {FAIRY,}
#, Human, Kappa, Lunarian, Oni, Doll, Devil, Yukionna, Zombie, Hermit, Magician, Spirit
enum JOB_ID {TRBLR, THIEF,}
enum WEP_ID {SPEAR, KNIFE,}
enum DAMAGE_TYPE {PHYS, MAG, TRUE,}
enum CORE_STAT {MOVE, LIFE, COMP, PWR, MAG, ELEG, CELE, BAR, HA,}
enum STATUS_EFFECT {ALL, RANDOM, ACTED, SLEEP,}
#Skill Enums
#Enemy, Self, Ally, Self+(This is Self and Ally), Other(Enemy or Ally, not Self)

#Effect Enums
enum EFFECT_TYPE {TIME, BUFF, DEBUFF, STATUS, DAMAGE, HEAL, CURE, TOSS, SHOVE, WARP, DASH, ADD_SKILL, ADD_PASSIVE,}
enum EFFECT_TARGET {SELF, TARGET, GLOBAL}

