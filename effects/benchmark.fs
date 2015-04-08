uniform sampler2D empty;
uniform sampler2D from;
uniform sampler2D to;
uniform float time;
uniform float transition_time;
uniform float delta_time;
varying vec2 vUv;

void main() {
    if (abs(delta_time*2.0-vUv.x) <= 0.0005)
        gl_FragColor = vec4(0.0,1.0,0.0,1.0);
    else if (abs(0.01666*2.0-vUv.x) <= 0.0005 )
        gl_FragColor = vec4(1.0,0.5,0.0,1.0);
    else if (abs(0.01666*4.0-vUv.x) <= 0.0005 )
        gl_FragColor = vec4(1.0,0.5,0.0,1.0);
    else if (abs(0.01666*8.0-vUv.x) <= 0.0005 )
        gl_FragColor = vec4(1.0,0.5,0.0,1.0);
    else {
        gl_FragColor = mix(texture2D(from, vUv), texture2D(to, vUv), transition_time);
    }

}

