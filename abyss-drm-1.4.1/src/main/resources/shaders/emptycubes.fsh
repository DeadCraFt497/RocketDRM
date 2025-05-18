/*
 * Original shader from: https://www.shadertoy.com/view/wlyyWd
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

float sub(float d1, float d2){return max(-d1, d2);}

float sdBox( vec3 p, vec3 b ){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z))-.04,0.0);
}

float hash12(vec2 p){
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void trn(inout vec3 p){
    p.yz*=rot(-0.8);
    p.xy*=rot(0.475);
    p.x += iTime + 50.;
}

#define b vec3(5., 5., 0.)

float map(vec3 rp){
    float d = 999.;
    vec3 p = rp-vec3(0., -5., 9.);
    vec3 pp = p;
    trn(pp);

    for(float i = 0.; i < 2.; i++){
        p = pp;
        vec3 id = floor(p / max(b, 0.0001));
        p.z += i*-5.;

        float rnd = hash12(i*33.+id.xy*vec2(333., 588.));
        p = mod(p, b)-b*.5;

        p.xz *= rot(sign(rnd-0.5)*.8*iTime+id.x+id.y);
        p.xy *= rot(sign(rnd-0.5)*.8*iTime+id.x+id.y);

        d = min(sdBox(p, vec3(1.6 - rnd*0.2, 1.6 - rnd*0.4, 1.0 + rnd*0.9)), d);
        if(rnd > 0.4) d=sub(length(p)-1.68, d);
    }

    return d;
}


vec3 normal( in vec3 pos ){
    vec2 e = vec2(0.002, -0.002);
    return normalize(
        e.xyy * map(pos + e.xyy) +
        e.yyx * map(pos + e.yyx) +
        e.yxy * map(pos + e.yxy) +
        e.xxx * map(pos + e.xxx));
}


void mainImage( out vec4 f, in vec2 u ){
    vec2 uv = vec2(u.xy - 0.5*R.xy)/R.y;
    vec3 rd = normalize(vec3(0., 0.0, 1.));
    vec3 ro = vec3(uv * 12., 0.);

    float d = 0.0, t = 0.0, ns = 0.;
    for(int i = 0; i < 64; i++){
    	d = map(ro + rd*t);
        if(abs(d) < 0.01 || t > 40.)break;
        t += d * .55;
        ns++;
    }

    vec3 p = ro + rd*t;
    vec3 n = normal(p);

    vec3 lp = vec3(-2., 37.0, -30.);
    vec3 ld = normalize(lp-p);

    float dif = max(dot(n, ld), .3);
    vec3 col = .43 + .3*cos(vec3(0.5, 2., 1.1)*(n.x+n.y+n.z)*1.2 + vec3(2., 1.8, 0.2));

    col *= max(ss(1.85, 0.6, ns/24.), 0.03) * dif;

    col = mix(vec3(0.0), col, exp(-t*t*t*0.0001));
    col = pow(col*1.4, vec3(1.85));

    col*=ss(.42, .419, abs(uv.y));

    f = vec4(sqrt(clamp(col, .0, 1.)), 1.);
}
// --------[ Original ShaderToy ends here ]---------- //

void main(void)
{
    mainImage(gl_FragColor, gl_FragCoord.xy);
}