shader_type spatial;

uniform float amplitude = 11.0;
uniform float frequency = 0.03;
uniform int octaves = 4;
uniform float lacunarity = 2.0;
uniform float gain = 0.5;
varying vec3 v_world_pos;

uniform float color_frequency = 0.05;
uniform int color_octaves = 3;
uniform float color_lacunarity = 2.5;
uniform float color_gain = 0.000001;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f); // smoothstep

    return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), f.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amp = 1.0;
    float freq = frequency;
    for (int i = 0; i < octaves; i++) {
        value += amp * noise(p * freq);
        freq *= lacunarity;
        amp *= gain;
    }
    return value;
}

void vertex() {
    vec3 world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float h = fbm(world_vertex.xz) * amplitude;
    VERTEX.y += h;
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


void fragment() {


    vec3 sand = vec3(0.76, 0.70, 0.50);
    vec3 grass = vec3(0.28, 0.50, 0.20);
    ALBEDO = mix(sand, grass, h);
}
