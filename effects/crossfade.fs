precision mediump float;
uniform sampler2D empty;
uniform sampler2D from;
uniform sampler2D to;
uniform float time;
uniform int transition_type;
uniform float transition_time;
varying vec2 vUv;

void main() {
    gl_FragColor = mix(texture2D(from, vec2(vUv)), texture2D(to, vec2(vUv)), transition_time);
}

