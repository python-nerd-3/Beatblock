#pragma language glsl3

uniform int gameWidth = 600;
uniform int gameHeight = 360;

uniform Image shuvCanvas;


vec4 effect(vec4 color, Image tex, vec2 uv, vec2 fc) {
	vec4 outColor = color * Texel(tex, uv);
	
	if(outColor == vec4(1.0,1.0,1.0,1.0)){
		outColor = vec4(1.0,1.0,1.0,2.0) - Texel(shuvCanvas, uv);
	}

	return outColor;
}