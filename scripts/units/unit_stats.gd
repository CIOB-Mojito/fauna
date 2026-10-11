class_name UnitStats
extends Resource

@export var display_name := "Unit"
@export var role_text := ""
@export var cost := 0
@export var max_health := 100.0
@export var vision_radius := 9.5
@export var move_speed := 4.5
@export var attack_range_min := 0.0
@export var attack_range_max := 0.0
@export var damage := 0.0
@export var reload_time := 1.0
@export var amphibious := false
@export var armor_front := 0.0
@export var armor_side := 0.0
@export var armor_rear := 0.0
@export var armor_top := 0.0
@export var armor_bottom := 0.0
@export var ammo := 0
@export var fuel := 0.0
@export var fuel_consumption := 0.0


func has_weapon() -> bool:
	return damage > 0.0 and attack_range_max > 0.0


func shots_per_second() -> float:
	if reload_time <= 0.0:
		return 0.0
	return 1.0 / reload_time


func damage_per_second() -> float:
	return damage * shots_per_second()