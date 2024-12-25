extends MeshInstance3D

@onready var PauseMenu=Watch
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var my_surf=mesh.surface_get_material(2)
	my_surf.set_shader_parameter("texture_albedo",Watch.ViewpTexture)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
