uniform sampler2D u_empty;
uniform sampler2D u_from;
uniform sampler2D u_to;
uniform float u_time;
uniform float u_transition_time;
uniform float u_delta_time;

varying vec2 v_uv;

void main() {
    vec4 c1 = texture2D(u_from, v_uv);
    vec4 c2 = texture2D(u_to, v_uv);
    vec4 col = mix(c1, c2, u_transition_time);
    #if 1
    float a = 1.0-clamp(abs(u_delta_time*2.0-v_uv.x)*1000.0,.0,1.0);
    float d = step(fract(v_uv.x*30.0),0.95);
    col.r+=a-1.0+d;
    col.b+=1.0-d-a;
    col.g-=(a+1.0-d);
    #endif
    gl_FragColor = col;
}

