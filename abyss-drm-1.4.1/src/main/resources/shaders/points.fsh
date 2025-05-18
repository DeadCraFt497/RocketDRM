/*
 * Original shader from: https://www.shadertoy.com/view/wlyczd
 */

#ifdef GL_ES
precision mediump float;
#endif

// glslsandbox uniforms
uniform float time;
uniform vec2 resolution;

// shadertoy emulation
#define iTime time
#define iResolution resolution

// --------[ Original ShaderToy begins here ]---------- //
#define R(a) mat2(cos(a),sin(a),-sin(a),cos(a))
void mainImage(out vec4 O, vec2 C)
{
    O-=O;
    vec2 r=iResolution.xy;
    vec3 p,q,d=vec3((C-.5*r)/r.y,.8);
    float g=0.,e=0.,l=0.,s=0.;
    for(float i=0.;i<80.;++i)
    {
        s=4.;
        p=g*d;
        p.z-=.9;
        p.xy*=R(iTime*.1);
        p.yz*=R(iTime*.1);
        q=p;
        s=3.;
        for(int j=0;j<3;++j)
        p-=clamp(p,-1.,1.)*2.,
        p=p*(l=5.*clamp(.6/min(dot(p,p),2.),0.4,1.))+q,
        s*=l;
        g+=e=length(p*p)/s;
        e<.008?O.xyz+=abs(cos(d+log(s)))/i:p;
    }
    O.xyz*=3.0;
    O.w = 1.0;

}
// --------[ Original ShaderToy ends here ]---------- //

void main(void)
{
    mainImage(gl_FragColor, gl_FragCoord.xy);
}