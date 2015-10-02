uniform sampler2D empty;
uniform sampler2D from;
uniform sampler2D to;
uniform float transition_time;
uniform float time;

varying vec2 Uv1;
varying vec2 Uv2;
varying vec2 Uv3;

varying float diff;

void main() {
    vec4 f=texture2D(from, uv);
    vec4 t=texture2D(to, uv);
    diff=length(f-t);

    Uv1=uv;
    Uv2 = (uv - 0.5) * transition_time + 0.5;
    Uv3 = (uv - 0.5) / (1.0-transition_time) + 0.5;
    gl_Position = vec4(position, 1.0);
}
