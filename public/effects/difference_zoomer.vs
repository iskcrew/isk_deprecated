attribute vec3 a_pos;
attribute vec2 a_tex_uv;

uniform float u_transition_time;
uniform float u_time;
uniform sampler2D u_empty;
uniform sampler2D u_from;
uniform sampler2D u_to;

varying vec2 v_uv1;
varying vec2 v_uv2;
varying vec2 v_uv3;
varying float v_diff;

void main() {
    vec4 f = texture2D(u_from, a_tex_uv);
    vec4 t = texture2D(u_to, a_tex_uv);
    v_diff = length(f-t);

    v_uv1 = a_tex_uv;
    v_uv2 = (a_tex_uv - 0.5) * u_transition_time + 0.5;
    v_uv3 = (a_tex_uv - 0.5) / (1.0-u_transition_time) + 0.5;

    gl_Position = vec4(a_pos, 1.0);
}
