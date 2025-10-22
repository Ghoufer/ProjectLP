extends Control
class_name ItemSlot

@onready var item_sprite: Sprite2D = $ItemSprite
@onready var quantity_label: Label = $Quantity

var stack : ItemStack:
	set(val):
		quantity_label.text = str(val.quantity)
		item_sprite.texture = val.item_data.icon
	
