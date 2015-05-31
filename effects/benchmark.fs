uniform sampler2D empty;
uniform sampler2D from;
uniform sampler2D to;
uniform float time;
uniform float transition_time;
uniform float delta_time;
varying vec2 Uv1;

void main() {
    vec4 c1 = texture2D(from, Uv1);
    vec4 c2 = texture2D(to, Uv1);
    vec4 col = mix(c1, c2, transition_time);
    #if 1
    float a = 1.0-clamp(abs(delta_time*2.0-Uv1.x)*1000.0,.0,1.0);
    float d = step(fract(Uv1.x*30.0),0.95);
    col.r+=a-1.0+d;
    col.b+=1.0-d-a;
    col.g-=(a+1.0-d);
    #endif
    gl_FragColor = col;
}

