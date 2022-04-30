shader_type canvas_item;
uniform vec4 newcolor = vec4(0, 1, 0, 0);
uniform vec4 oldcolor = vec4(1, 0, 0, 1);
uniform float tol = 5;
void fragment(){
	vec4 curcolor = texture(TEXTURE, UV);
	if (distance(curcolor, oldcolor) < tol){
		COLOR = newcolor + curcolor - oldcolor;
	} else {
		COLOR = curcolor;
	}
}