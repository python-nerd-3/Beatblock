#pragma language glsl3

uniform int gameWidth = 600;
uniform int gameHeight = 360;
uniform int c = -1;

const vec4 originalcolors[4] = vec4[4](
	vec4(1.0,1.0,1.0,1.0), //white
	vec4(0.0,0.0,0.0,1.0), //black
	vec4(1.0,0.0,0.0,1.0), //red
	vec4(0.0,0.0,1.0,1.0)  //blue
);

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 fc) {
    vec4 source = color * Texel(tex, uv);
    if (source.a > 0.0 || c == -1) {
        return source;
    }
	float a = 0.0;
    vec2 step = vec2(1.0 / gameWidth, 1.0 / gameHeight);
    a += Texel(tex, uv + vec2(step.x, 0)).a;
    a += Texel(tex, uv + vec2(-step.x, 0)).a;
    a += Texel(tex, uv + vec2(0, step.y)).a;
    a += Texel(tex, uv + vec2(0, -step.y)).a;
	return vec4(originalcolors[c].r, originalcolors[c].g, originalcolors[c].b, a);
}