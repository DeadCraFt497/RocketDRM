#define WAVES 10.
#ifdef GL_ES
precision mediump float;
#endif

uniform float time;
uniform vec2 resolution;

void main(void){
    vec2 uv=-1.+2.*gl_FragCoord.xy/resolution.xy;

    vec3 color=vec3(0.);

    for(float i=0.;i<WAVES+1.;i++){
        float freq=1.8;

        vec2 p=vec2(uv);

        p.x+=i*.04+freq*.03;
        p.y+=sin(p.x*10.+time)*cos(p.x*2.)*freq*.2*((i+1.)/WAVES);
        float intensity=abs(.01/p.y)*clamp(freq,.35,2.);
        color+=vec3(1.*intensity*(i/5.),.1*intensity,3.*intensity)*(3./WAVES);
    }

    gl_FragColor=vec4(color,1.);
}