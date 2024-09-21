#pragma language glsl3

uniform int gameWidth = 600;
uniform int gameHeight = 360;
uniform float time = 0.0;

uniform float hglitch_strength = 0.0;
uniform float hglitch_resolution = 2;

uniform float vglitch_strength = 0.0;
uniform float vglitch_resolution = 2;

uniform float hwaves_strength = 0.0;
uniform float hwaves_period = 16.0;
uniform float hwaves_offset = 0.0;

uniform float vwaves_strength = 0.0;
uniform float vwaves_period = 16.0;
uniform float vwaves_offset = 0.0;

uniform Image effectCanvas;

uniform float pixelate = 1.0;

float random(vec2 st)
{
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

const vec4 originalcolors[4] = vec4[4](
	vec4(1.0,1.0,1.0,1.0), //white
	vec4(0.0,0.0,0.0,1.0), //black
	vec4(1.0,0.0,0.0,1.0), //red
	vec4(0.0,0.0,1.0,1.0)  //blue
);

int colortoindex(vec4 color){
	if(color == originalcolors[0]){
		return 0;
	} else if(color == originalcolors[1]){
		return 1;
	} else if(color == originalcolors[2]){
		return 2;
	} else if(color == originalcolors[3]){
		return 3;
	} else {
		return -1;
	}
}

void doHglitch(inout vec2 uv, vec2 step){
	if(hglitch_strength != 0.0){
		uv.x = uv.x + (random(vec2(0,floor((uv.y*gameHeight)/hglitch_resolution)+time)) - 0.5) * step.x * hglitch_strength;
	}
}
void doVglitch(inout vec2 uv, vec2 step){
	if(vglitch_strength != 0.0){
		uv.y = uv.y + (random(vec2(floor((uv.x*gameWidth)/vglitch_resolution)+time,0)) - 0.5) * step.y * vglitch_strength;
	}
}

void doHwaves(inout vec2 uv, vec2 step){
	if(hwaves_strength != 0.0){
		uv.x = uv.x + sin(((uv.y/step.y + hwaves_offset) * 3.1415)/hwaves_period) * step.x * hwaves_strength;
	}
}
void doVwaves(inout vec2 uv, vec2 step){
	if(vwaves_strength != 0.0){
		uv.y = uv.y + sin(((uv.x/step.x + vwaves_offset) * 3.1415)/vwaves_period) * step.y * vwaves_strength;
	}
}

void doPixelate(inout vec2 uv, vec2 step){
	if(pixelate != 1.0){
		uv = floor((uv / step) / pixelate) * step * pixelate;
	}
}


void doEffectCanvas(vec2 uv, Image tex, inout vec4 outcolor){
	vec4 effectpixel = Texel(effectCanvas, uv);
	if(effectpixel.r != 0.0){
		int redValue = int(effectpixel.r * 255.0);
		
		switch(colortoindex(outcolor)){
		case 0:
			outcolor = originalcolors[redValue & 0x03];
			break;
		case 1:
			outcolor = originalcolors[(redValue & 0x0c) >> 2];
			break;	
		case 2:
			outcolor = originalcolors[(redValue & 0x30) >> 4];
			break;
		case 3:
			outcolor = originalcolors[(redValue & 0xc0) >> 6];
			break;
		}
		
		
		
		//outcolor = originalcolors[int(mod(colortoindex(outcolor) + 2,4))];
		
	}
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 fc) {

    vec2 step = vec2(1.0 / gameWidth, 1.0 / gameHeight);
	
	doHwaves(uv,step);
	doVwaves(uv,step);
	doHglitch(uv, step);
	doVglitch(uv, step);
	doPixelate(uv, step);
	
	vec4 outcolor = color * Texel(tex, uv);
	
	doEffectCanvas(uv, tex, outcolor);

	return outcolor;
}