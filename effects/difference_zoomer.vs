uniform float transition_time;
uniform float time;

varying vec2 Uv1;
varying vec2 Uv2;
varying vec2 Uv3;

void main() {
    Uv1=uv;
    Uv2 = (uv - 0.5) * transition_time + 0.5;
    Uv3 = (uv - 0.5) / (1.0-transition_time) + 0.5;
    gl_Position = vec4(position, 1.0);
}

