#version 330

uniform int     gTimelinePoint;
uniform float   gPointTime;
uniform float   gTime;
uniform vec2    gRes;


#define RAY_MAX_LENGTH 150.0
#define NUM_MAX_STEPS  150
#define MIN_DISTANCE   0.05



float sphereSDF(vec3 p, vec3 pos, float size) {
	return length(p - pos) - size;
}

mat3 rotxy(vec2 a) {
	vec2 c = cos(a);
	vec2 s = sin(a);
	return mat3(c.y, 0.0, -s.y, s.y * s.x, c.x, c.y * s.x, s.y * c.x, -s.x, c.y * c.x);
}

float distort(vec3 p, float a, float v) {
	return sin(a * p.x) * cos(a * p.y) * sin(a * p.z) * v;
}

vec3 repeat(vec3 p, vec3 f) {
	return mod(p, f) - 0.5 * f;
}

vec3 repeat_xz(vec3 p, vec2 f) {
	vec2 r = mod(p.xz, f) - 0.5 * f;
	return vec3(r.x, p.y, r.y);
}


float create_world(vec3 p) {
	float res = 0.0;

	if(gTimelinePoint == 1 || gTimelinePoint == 2) {
		vec3 rep = repeat_xz(p, vec2(7.0, 7.0));

		float r0 = sphereSDF(rep, vec3(0.0, 0.0, 1.0), 1.0);
		float r1 = sphereSDF(rep, vec3(0.0, 8.5, 1.0), 1.0);

		res = min(r0, r1);
	}
	else {
		res = sphereSDF(p, vec3(0.0, 0.0, 5.0), 1.0);
		res += distort(p, 2.135 + gTime + length(p.zxy), 0.1253 * cos(gTime));
	}

	return res;
}


/*
vec3 compute_normal(vec3 p) {
	float dist = create_world(p);
	vec2 s = vec2(0.01, 0.0);
	vec3 n = vec3(
				create_world(p - s.xyy),
				create_world(p - s.yxy),
				create_world(p - s.yyx)
			);

	return normalize(dist - n);
}

vec3 compute_light(vec3 p) {

	vec3 diffuse_color = vec3(0.8, 0.1, 0.1);
	vec3 ambient_color = vec3(0.03, 0.03, 0.03);


	vec3 light_pos = vec3(2.0, 3.0, 1.0);
	vec3 v = normalize(light_pos - p);
	vec3 norm = compute_normal(p);

	vec3 diffuse = diffuse_color * max(dot(v, norm), 0.0);
	return diffuse + ambient_color;
}
*/


void ray_march(vec3 ro, vec3 rd) {
	
	float ray_length = 0.0;
	float closest = 99999.9;
	vec3 color        = vec3(0.0, 0.0, 0.1);
	vec3 glow_color   = vec3(0.5, 0.0, 1.0);
	vec3 shape_color  = vec3(0.0, 0.0, 0.0);


	int i = 0;

	for(; i < NUM_MAX_STEPS; i++) {
		vec3 p = ro + rd * ray_length;
		float dist = create_world(p);
		
		if(dist < closest) {
			closest = dist;
		}
		
		if(abs(dist) <= MIN_DISTANCE) {
			//color += shape_color;
			//float d = 1.0 - (float(i) / float(NUM_MAX_STEPS));
			//shape_color = 0.5 + 0.5 * cos(d + vec3(0,2,4));
			//color = vec3(d * shape_color);
			break;

		}
		
		if(ray_length >= RAY_MAX_LENGTH) {
			float glow = 1.2 / closest * 0.025;
			color += glow_color * glow;
			break;

		}
		
		ray_length += dist;
	}
	
	float d = (float(i) / float(NUM_MAX_STEPS));
	color += vec3(d * vec3(1.0, 0.0, 1.0));

	if(gTimelinePoint < 2) {
		color *= min(1.0, gPointTime*0.25);
	}

	gl_FragColor = vec4(color, 1.0);
}


vec2 pixelate(vec2 xy, float amount, float detail) {
	float dx = amount*(1.0/detail);
	float dy = amount*(1.0/detail);
	return vec2(dx * floor(xy.x / dx), dy * ceil(xy.y / dy));
}	


vec3 get_raydir(float fov) {
	vec2 xy = gl_FragCoord.xy - gRes.xy * 0.5;

	if(gTimelinePoint == 0) {
		float t = gPointTime * 0.39;
		if(gPointTime >= 3.9) {
			xy *= mat2(cos(t*2.0), -sin(t*2.0), sin(t*2.0), cos(t*2.0));
		}
		else {
			t = -t;
			xy *= mat2(cos(t*1.5), -sin(t*1.5), sin(t*1.5), cos(t*1.5));
		}
	}
	else if(gTimelinePoint >= 2) {
		float t = gPointTime * 0.45;
		xy *= mat2(cos(t), -sin(t), sin(t), cos(t));
	
	}

	float hf = tan((90.0 - fov * 0.5) * (3.14159/180.0));
	return normalize(vec3(xy, (gRes.y * 0.5 * hf)));
}



void main() {

	vec3 ro = vec3(0.0);
	vec3 rd = get_raydir(60.0);

	if(gTimelinePoint == 0) {

		float z = -8.5;
		if(gPointTime > 2.0 && gPointTime < 3.9) {
			z = -5.0;
		}
		else if(gPointTime >= 3.9) {
			z = -3.5 + gPointTime*0.85;
		}

		ro = vec3(0.0, 0.0, z);
	}
	else if(gTimelinePoint == 1) {
		ro = vec3(0.0, gPointTime*0.45, -5.0);

	}
	else if(gTimelinePoint >= 2) {
		ro = vec3(cos(gPointTime)*12.0, 4.0, gPointTime*25.5);

	}


/*	
	if(gTimelinePoint == 0) {
		ro = vec3(0.0, 1.0, -2.0);
	}
	else if(gTimelinePoint == 1) {
		float x = cos(gTime)*5.0;
		float z = sin(gTime)*5.0;
		ro = vec3(x, 0.0, z);
		rd *= rotxy(vec2(0.0, cos(gTime)));
	}
*/
	//rd *= rotxy(vec2(0.0, cos(gTime)*0.5));


	ray_march(ro, rd);
}






