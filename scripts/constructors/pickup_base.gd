@tool
extends Node3D
class_name PickUpBase

@export var pickup_data : Pickup

var pickup_mesh = null
var old_pickup_mesh = null

var old_pickup_scale: Vector3

var old_name: String = name

signal pickup_finish

#TODO: Rarely a second model will show up in the editor, probably instancing issue.
#seems to mostly happen when duplicating nodes. Groups to the rescue???

#TODO: Maybe I should just refresh the entire node if ANY data changes?

# A lot of this code is meant for the editor to dynamically load and unload -
# The packed model scene for the pickup mesh inside the Pickup Data.

func _ready() -> void:
	if !Engine.is_editor_hint():
			update_mesh()

func _process(delta: float) -> void:
	if pickup_mesh != null:
		pickup_mesh.rotation.y += 2 * delta
	
	#Update the editor model, scale, and name if altered
	if Engine.is_editor_hint():
		if pickup_data != null:
			get_tree().call_group("mesh", "remove_instance")
			if pickup_data.model != null:
				if pickup_data.model.changed:
					if old_pickup_mesh != pickup_data.model or old_pickup_scale != pickup_data.scale:
						update_mesh()
			if pickup_data.name_editor != null:
					if old_name != pickup_data.name_editor:
						name = pickup_data.name_editor
						old_name = name

func update_mesh():
		if pickup_data != null:
			if pickup_mesh != null:
				pickup_mesh.queue_free()
			pickup_mesh = pickup_data.model.instantiate()
			pickup_mesh.scale = pickup_data.scale
			pickup_mesh.position = pickup_data.position
			pickup_mesh.rotation = pickup_data.rotation
			old_pickup_mesh = pickup_data.model
			old_pickup_scale = pickup_data.scale
			pickup_mesh.add_to_group("mesh")
			add_child(pickup_mesh)
			
#SIGNAL FUNCTIONS
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.emit_signal("pickup_detected", self, self.pickup_data)
		
func _on_pickup_finish() -> void:
	self.queue_free()

#TODO: get this bad boy working
func remove_instance():
	print("test")
	#self.queue_free()
	
#Not committed to deleting this yet.
func _on_tree_entered() -> void:
	self.name = pickup_data.name_editor
	old_name = name
	#if Engine.is_editor_hint():
		#update_mesh()
