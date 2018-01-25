attribute vec3 a_pos;
attribute vec2 a_tex_uv;

uniform float transition_time;
uniform float time;

varying vec2 v_uv;

void main() {
    v_uv=a_tex_uv;
    gl_Position = vec4(a_pos, 1.0);
}
