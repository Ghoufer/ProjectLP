shader_type spatial;

void fragment() {
	NORMAL = -normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
}