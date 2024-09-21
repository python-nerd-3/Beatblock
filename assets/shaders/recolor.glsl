#pragma language glsl3

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 fc) {
    vec4 source = Texel(tex, uv);
    color.a = source.a;
	return color;
}