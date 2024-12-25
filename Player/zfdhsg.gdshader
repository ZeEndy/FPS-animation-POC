shader_type spatial;

const int maxbonecnt = 200;
uniform vec4 aq0[maxbonecnt];
uniform vec4 aq1[maxbonecnt];
uniform mat4 bonemat[maxbonecnt];

mat4 DQToMatrix(vec4 Qn, vec4 Qd)
{
	//Original version of this function is in https://users.cs.utah.edu/~ladislav/dq/dqs.cg
	mat4 M = mat4(0.0);
	float len2 = dot(Qn, Qn);
	float w = Qn.w, x = Qn.x, y = Qn.y, z = Qn.z;
	float t0 = Qd.w, t1 = Qd.x, t2 = Qd.y, t3 = Qd.z;

	M[0][0] = w*w + x*x - y*y - z*z;
	M[1][0] = 2.0*x*y - 2.0*w*z;
	M[2][0] = 2.0*x*z + 2.0*w*y;
	M[0][1] = (2.0*x*y + 2.0*w*z);
	M[1][1] = (w*w + y*y - x*x - z*z);
	M[2][1] = (2.0*y*z - 2.0*w*x);
	M[0][2] = 2.0*x*z - 2.0*w*y;
	M[1][2] = 2.0*y*z + 2.0*w*x;
	M[2][2] = w*w + z*z - x*x - y*y;

	M[3][0] = -2.0*t0*x + 2.0*w*t1 - 2.0*t2*z + 2.0*y*t3;
	M[3][1] = -2.0*t0*y + 2.0*t1*z - 2.0*x*t3 + 2.0*w*t2;
	M[3][2] = -2.0*t0*z + 2.0*x*t2 + 2.0*w*t3 - 2.0*t1*y;

	M /= len2;

	return M;
}

void vertex() {
	//Original version of this function is in https://users.cs.utah.edu/~ladislav/dq/dqs.cg
	vec4 dq00 = aq0[BONE_INDICES.x]; vec4 dq01 = aq1[BONE_INDICES.x];
	vec4 dq10 = aq0[BONE_INDICES.y]; vec4 dq11 = aq1[BONE_INDICES.y];
	vec4 dq20 = aq0[BONE_INDICES.z]; vec4 dq21 = aq1[BONE_INDICES.z];
	vec4 dq30 = aq0[BONE_INDICES.w]; vec4 dq31 = aq1[BONE_INDICES.w];

	if (dot(dq00, dq10) < 0.0) {dq10 *= -1.0;dq11 *= -1.0;}
	if (dot(dq00, dq20) < 0.0) {dq20 *= -1.0;dq21 *= -1.0;}
	if (dot(dq00, dq30) < 0.0) {dq30 *= -1.0;dq31 *= -1.0;}

	vec4 blend_q0 = BONE_WEIGHTS.x*dq00 + BONE_WEIGHTS.y*dq10 + BONE_WEIGHTS.z*dq20 + BONE_WEIGHTS.w*dq30;
	vec4 blend_q1 = BONE_WEIGHTS.x*dq01 + BONE_WEIGHTS.y*dq11 + BONE_WEIGHTS.z*dq21 + BONE_WEIGHTS.w*dq31;

	mat4 M = DQToMatrix(blend_q0, blend_q1);
	VERTEX = (M*vec4(VERTEX,1.0)).xyz;
	NORMAL = (M*vec4(NORMAL,0.0)).xyz;
}
