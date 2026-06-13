extends Node3D

@export var color_mat : StandardMaterial3D
@export var lifetime : float = 0.0

func _ready():
	# @FIXME seems a bit overkill to duplicate quad mesh for each particle node instance
	var quad_mesh := $GPUParticles3D.draw_pass_1 as QuadMesh
	quad_mesh = quad_mesh.duplicate()
	quad_mesh.material = color_mat
	$GPUParticles3D.draw_pass_1 = quad_mesh
	if lifetime > 0.0:
		$GPUParticles3D.lifetime = lifetime
	$GPUParticles3D.emitting = true


func _on_gpu_particles_3d_finished() -> void:
	"""
	Emit once and die. This is the hard life of particles.
	"""
	queue_free()
