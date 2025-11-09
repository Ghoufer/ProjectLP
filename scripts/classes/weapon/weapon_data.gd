extends Resource
class_name WeaponData

enum WeaponType { FIST, SWORD }

@export var weapon_name : String
@export var weapon_type : WeaponType
@export var base_damage : int
@export var combos : Array[Combo]

@export var light_attack_data: AttackData
@export var heavy_attack_data: AttackData
@export var special_attack_data: AttackData
