@tool
extends MeshInstance3D

var array_q0 = []
var array_q1 = []

var skl : Skeleton3D
var skl_bncnt = 0
const maxbonecnt = 200

var Mj

var matcnt

# Called when the node enters the scene tree for the first time.
func _ready():
	print(skeleton)
	skl= get_parent_node_3d()
	skl_bncnt = skl.get_bone_count()
	matcnt = get_surface_override_material_count()
	skl.connect("skeleton_updated",sendToShader)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#sendToShader()

func QuatTrans2UDQ(q0, t):
	#Original version of this function is in https://users.cs.utah.edu/~ladislav/dq/dqconv.c
	var q1 = Quaternion()
	q1.w = -0.5*(t[0]*q0.x + t[1]*q0.y + t[2]*q0.z)
	q1.x = 0.5*( t[0]*q0.w + t[1]*q0.z - t[2]*q0.y)
	q1.y = 0.5*(-t[0]*q0.z + t[1]*q0.w + t[2]*q0.x)
	q1.z = 0.5*( t[0]*q0.y - t[1]*q0.x + t[2]*q0.w)
	return q1

func getq0q1():
	array_q0 = []
	array_q1 = []
	var i = 0
	while (i < skl_bncnt):
		var Mjt = skl.get_bone_global_pose(i)
		var Mj0 = skl.get_bone_global_rest(i)
		var Mj0i = Mj0.inverse()
		Mj = Mjt*Mj0i
		var t = Mj.origin
		var q0 = (Mj.basis).get_rotation_quaternion()
		var q1 = QuatTrans2UDQ(q0,t)
		array_q0.append(q0)
		array_q1.append(q1)
		i = i + 1

func sendToShader():
	getq0q1()
	var currentmat=material_override 
	#var i = 0
	#while (i < matcnt):
		#currentmat = get_surface_override_material(i)
	currentmat.set_shader_parameter("aq0", array_q0)
	currentmat.set_shader_parameter("aq1", array_q1)
		#i = i + 1
