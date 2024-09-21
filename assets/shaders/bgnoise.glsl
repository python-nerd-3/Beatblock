#pragma language glsl3

uniform float time = 0.0;
uniform float chance = 0.0;

float random(vec2 st)
{
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}


vec4 effect(vec4 color, Image tex, vec2 uv, vec2 fc) {
    vec4 source = color * Texel(tex, uv);
    if(random(vec2(uv.x+time,uv.y+time)) < chance){
		source.a = 0.0;
	}
	return source;
}