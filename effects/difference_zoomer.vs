precision mediump float;
uniform int transition_type;
uniform float transition_time;
uniform float time;

varying vec2 vUv;
void main() {
    vUv=uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

