uniform sampler2D empty;
uniform sampler2D from;
uniform sampler2D to;
uniform float time;
uniform float transition_time;
varying vec2 vUv;

void main() {
    gl_FragColor = mix(texture2D(from, vUv), texture2D(to, vUv), transition_time);
    gl_FragColor += mix(vec4(0,0,0,1), vec4(.5,0,0,1), cos(time)*0.5+0.5);
}

