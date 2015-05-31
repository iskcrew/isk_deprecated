uniform float transition_time;
uniform float time;
varying vec2 Uv1;

void main() {
    Uv1=uv;
    gl_Position = vec4(position, 1.0);
}

