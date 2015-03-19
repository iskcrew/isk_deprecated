uniform sampler2D empty;
uniform sampler2D from;
uniform sampler2D to;
uniform float time;
uniform float transition_time;
varying vec2 vUv;

void main()
{
    //vec2 uv = abs(gl_FragCoord.xy / resolution.xy);
    vec2 uv = vUv;
    vec2 uv2 = (uv - 0.5) * transition_time + 0.5;
    vec2 uv3 = (uv - 0.5) / (1.0-transition_time) + 0.5;
    vec4 f1=texture2D(from, uv2);
    vec4 f2=texture2D(from, uv3);
    vec4 t1=texture2D(to, uv2);
    vec4 t2=texture2D(to, uv3);
    vec4 e1=texture2D(empty, uv2);
    vec4 e2=texture2D(empty, uv3);
    
    if ((length(f1-t1)>=0.1) && (length(t1-e1)>=0.1))
        gl_FragColor = mix(texture2D(empty, uv), texture2D(to, uv2), transition_time);
    else if ((length(f2-t2)>=0.1) && (length(f2-e2)>=0.1))
        gl_FragColor = mix(texture2D(empty, uv), texture2D(from, uv3), 1.0-transition_time);
    else if (length(texture2D(to, uv) - texture2D(from, uv)) <=0.1)
        gl_FragColor = texture2D(from, uv);
    else
        gl_FragColor = texture2D(empty, uv);

} 

