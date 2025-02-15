@tool
extends Node3D

@export var pickup_data : Pickup
var pickup_mesh = null

var old_pickup_mesh = null

signal pickup_finish

#A lot of this code is meant for the editor to dynamically load and unload -
# The packed model scene for the pickup mesh inside the Pickup Data.

func _ready() -> void:
	if !Engine.is_editor_hint():
			update_mesh()
			add_child(pickup_mesh)

func _process(delta: float) -> void:
	if pickup_mesh != null:
		pickup_mesh.rotation.y += 2 * delta
	if Engine.is_editor_hint():
		#print(str(pickup_data.model))
		if pickup_data.model != old_pickup_mesh:
			update_mesh()

func update_mesh():
		if pickup_data != null:
			if pickup_mesh != null:
				pickup_mesh.queue_free()
			pickup_mesh = pickup_data.model.instantiate()
			print("is it null?" + str(pickup_mesh))
			pickup_mesh.scale = pickup_data.scale
			pickup_mesh.position = pickup_data.position
			pickup_mesh.rotation = pickup_data.rotation
			old_pickup_mesh = pickup_data.model
			add_child(pickup_mesh)

#SIGNAL FUNCTIONS
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.emit_signal("pickup_detected", self, self.pickup_data)
		
func _on_pickup_finish() -> void:
	self.queue_free()

func _on_tree_entered() -> void:
	if Engine.is_editor_hint():
		update_mesh()
		add_child(pickup_mesh)
