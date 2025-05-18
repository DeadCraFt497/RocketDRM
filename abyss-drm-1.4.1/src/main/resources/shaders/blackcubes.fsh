/*
 * Original shader from: https://www.shadertoy.com/view/WtcBzr
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
// Cole Peterson

#define R iResolution.xy
#define ss(a, b, t) smoothstep(a, b, t)
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

float hash12(vec2 p){
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float box( vec3 p, vec3 b ){
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sub(float d1, float d2){return max(-d1, d2);}

    #define b vec3(3., 3., 3.)
    #define r 0.45
    #define r2 0.42

void q(inout vec3 p, in float rnd){
    p.yz += .35*vec2(cos(iTime + rnd*333.), sin(iTime*2. + rnd*333.));
    p.x += sign(rnd-0.5)*iTime*(rnd+.4) + rnd*3.;
}

float map(vec3 p){
    float d = 999.;
    vec3 pp = p;

    vec2 id = floor(p.zy/b.xy);
    float rnd = hash12(id*733.3);

    q(p, rnd);

    p = mod(p, b)-b*0.5;

    p.xy*=rot(rnd*23.+iTime);
    p.xz*=rot(rnd*73.+iTime);

    d = min(box(p, vec3(r)), 4.7 - abs(pp.x));

    if(rnd > 0.6){
        d = sub(box(p, vec3(r2, r2, 2.2)), d);
        d = sub(box(p, vec3(r2, 2.2, r2)), d);
        d = sub(box(p, vec3(2.2, r2, r2)), d);
    }
    return d;
}

void mainImage( out vec4 f, in vec2 u ){
    vec2 uv = vec2(u.xy - 0.5*R.xy)/R.y;

    vec3 rd = normalize(vec3(uv, 0.8));
    vec3 ro = vec3(-1.8, .5, 0.);

    rd.xy *= rot(-.3);
    rd.xz *= rot(-.2);
    rd.yz *= rot(.7);

    ro.z += iTime*1.3;

    float d = 0.0, t = 0.0, ns = 0.;

    for(int i = 0; i < 80; i++){
        d = map(ro + rd*t);

        if(d < 0.002 || t > 40.) break;
        t += d * .55;
        ns++;
    }

    vec3 p = ro + rd*t;

    vec3 col = vec3(.001);

    col = mix(vec3(.05), col, exp(-t*t*t*0.0001));
    col = pow(col*3.4, vec3(1.6));


    f = vec4(pow(max(col, 0.), vec3(1./2.2)), 1);
}
// --------[ Original ShaderToy ends here ]---------- //

void main(void)
{
    mainImage(gl_FragColor, gl_FragCoord.xy);
}