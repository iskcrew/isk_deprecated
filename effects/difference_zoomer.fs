uniform sampler2D empty;
uniform sampler2D from;
uniform sampler2D to;
uniform float time;
uniform float transition_time;

varying vec2 Uv1;
varying vec2 Uv2;
varying vec2 Uv3;

void main()
{
    vec4 f1=texture2D(from, Uv1);
    vec4 f2=texture2D(from, Uv2);
    vec4 f3=texture2D(from, Uv3);
    vec4 t1=texture2D(to, Uv1);
    vec4 t2=texture2D(to, Uv2);
    vec4 t3=texture2D(to, Uv3);
    vec4 e1=texture2D(empty, Uv1);
    vec4 e2=texture2D(empty, Uv2);
    vec4 e3=texture2D(empty, Uv3);
    
    if ((length(f2-t2)>=0.1) && (length(t2-e2)>=0.1))
        gl_FragColor = mix(e1, t2, transition_time);
    else if ((length(f3-t3)>=0.1) && (length(f3-e3)>=0.1))
        gl_FragColor = mix(e1, f3, 1.0-transition_time);
    else if (length(t1 - f1) <=0.1)
        gl_FragColor = f1;
    else
        gl_FragColor = e1;

}
