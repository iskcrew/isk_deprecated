uniform sampler2D u_empty;
uniform sampler2D u_from;
uniform sampler2D u_to;
uniform float u_time;
uniform float u_transition_time;

varying vec2 v_uv;

void main() {
    gl_FragColor = mix(texture2D(u_from, v_uv), texture2D(u_to, v_uv), u_transition_time);
    gl_FragColor += mix(vec4(0,0,0,1), vec4(.5,0,0,1), cos(u_time)*0.5+0.5);
}

