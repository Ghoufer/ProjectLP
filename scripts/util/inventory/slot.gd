extends Control
class_name ItemSlot

@onready var item_sprite: Sprite2D = $ItemSprite
@onready var quantity_label: Label = $Quantity

signal _on_slot_clicked(event: InputEvent, clicked_stack: ItemStack)

var stack : ItemStack : set = set_property

func set_property(val: ItemStack) -> void:
	if val:
		quantity_label.text = str(val.quantity)
		item_sprite.texture = val.item_data.icon
		if quantity_label.text == '1': quantity_label.visible = false
		else: quantity_label.visible = true
	if stack and not val:
		quantity_label.text = ''
		item_sprite.texture = null
		self.quantity_label.visible = false
	
	stack = val
	

func _on_gui_input(event: InputEvent) -> void:
	_on_slot_clicked.emit(event, stack)
	
