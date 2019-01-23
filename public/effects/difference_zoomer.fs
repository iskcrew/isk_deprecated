uniform sampler2D u_empty;
uniform sampler2D u_from;
uniform sampler2D u_to;
uniform float u_transition_time;

varying vec2 v_uv1;
varying vec2 v_uv2;
varying vec2 v_uv3;

varying float v_diff;

void main()
{
    vec4 f1=texture2D(u_from, v_uv1);
    vec4 f2=texture2D(u_from, v_uv2);
    vec4 f3=texture2D(u_from, v_uv3);
    vec4 t1=texture2D(u_to, v_uv1);
    vec4 t2=texture2D(u_to, v_uv2);
    vec4 t3=texture2D(u_to, v_uv3);
    vec4 e1=texture2D(u_empty, v_uv1);
    vec4 e2=texture2D(u_empty, v_uv2);
    vec4 e3=texture2D(u_empty, v_uv3);
    
    if (v_diff>=0.01) 
        gl_FragColor = mix(f1, t1, u_transition_time);
    else if ((length(f2-t2)>=0.1) && (length(t2-e2)>=0.1))
        gl_FragColor = mix(e1, t2, u_transition_time);
    else if ((length(f3-t3)>=0.1) && (length(f3-e3)>=0.1))
        gl_FragColor = mix(e1, f3, 1.0-u_transition_time);
    else if (length(t1 - f1) <=0.1)
        gl_FragColor = f1;
    else
        gl_FragColor = e1;

}
