uniform float transition_time;
uniform float time;

varying vec2 vUv;
void main() {
    vUv=uv;
    gl_Position = vec4(position, 1.0);
}

