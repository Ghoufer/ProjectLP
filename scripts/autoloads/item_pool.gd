@tool
extends Node

const ITEM : PackedScene = preload("uid://cptevs6qmklst")

enum ITEMS {
	## Supplies
	NORMAL_ROCK,
	WOODEN_STICK,
	COAL,
	GOLD_BAR,
	
	## Weapons
	WOOD_SWORD,
}

func get_item_scene(item_path: ITEMS) -> PackedScene:
	match item_path:
		## Supplies
		ITEMS.NORMAL_ROCK: return preload("uid://dns5r67khxrd8")
		ITEMS.WOODEN_STICK: return preload("uid://cl1bpke3vaiv6")
		ITEMS.GOLD_BAR: return preload("uid://qugp8terlvu1")
		ITEMS.COAL: return preload("uid://de1y7vjetv3fa")
		
		## Weapons
		ITEMS.WOOD_SWORD: return preload("uid://dyh8torfxjjxx")
		
		_: return null
	
