
#ifdef GL_ES
precision mediump float;
#endif

uniform float time;
uniform vec2 resolution;

const float PI = 3.14159265359;
float snoise(in vec3 v);
float vmax(vec3 v) {return max(max(v.x, v.y), v.z);}
float fBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}
float fOpUnionRound(float a, float b, float r) {
    vec2 u = max(vec2(r - a,r - b), vec2(0));
    return max(r, min (a, b)) - length(u);
}

float map( in vec3 pos ) {
    pos -= snoise(pos*0.001+time);
    float d = -10. + pos.y + snoise(pos/41.+time)*1. + snoise(pos/3.+time)*3.+ snoise(pos/80.+time)*15.+ snoise(pos);
    pos += snoise(pos+time)+snoise(pos*2.+time);
    return d;
}


float castRay( in vec3 ro, in vec3 rd, inout float depth )
{
    float t = 0.0;
    float res;
    for( int i=0; i<100; i++ )
    {
        vec3 pos = ro+rd*t;
        res = map( pos );
        if( res < 0.01 || t > 150. ) break;
        t += res*1.;
        depth += 1./float(100);
    }
    return t;
}

float hash( float n ){
    return fract(sin(n)*3538.5453);
}


vec3 postEffects( in vec3 col, in vec2 uv, in float time )
{
    // vigneting
    col *= 0.7+0.3*pow( 16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y), 0.1 );
    return col;
}

vec3 render( in vec3 ro, in vec3 rd, in vec2 uv )
{
    float depth = 0.1;
    float t = castRay(ro,rd,depth);
    vec3 color = vec3(depth*uv.y,depth/5.,depth);
    color += smoothstep(0.3,0.6,depth)*vec3(0.2,0.2,0.1);
    color += smoothstep(0.6,1.,depth)*vec3(0.2,0.8,0.1);
    return color;
}


mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

vec3 orbit(float phi, float theta, float radius)
{
    return vec3(
    radius * sin( phi ) * cos( theta ),
    radius * cos( phi ) + cos( theta ),
    radius * sin( phi ) * sin( theta )
    );
}


void mainImage( out vec4 fragColor, in vec2 coords )
{
    vec2 uv = coords.xy / resolution.xy;
    vec2 q = coords.xy/ resolution.xy;
    vec2 p = -1.0+2.0*q;
    p.x *= resolution.x/ resolution.y;

    //Camera
    float radius = 60.;
    vec3 ro = orbit(PI/2.-.5,PI/2.+sin(time) * 0.*.35,radius);
    vec3 ta  = vec3(0.0, 0., 0.0);
    mat3 ca = setCamera( ro, ta, 0. );
    vec3 rd = ca * normalize( vec3(p.xy,1.2) );

    vec3 color = render( ro, rd, uv );
    color = postEffects( color, uv, time );
    fragColor = vec4(color,1.0);
}


vec4 permute(in vec4 x){return mod(x*x*34.+x,289.);}
float snoise(in vec3 v){
    const vec2 C = vec2(0.16666666666,0.33333333333);
    const vec4 D = vec4(0,.5,1,2);
    vec3 i  = floor(C.y*(v.x+v.y+v.z) + v);
    vec3 x0 = C.x*(i.x+i.y+i.z) + (v - i);
    vec3 g = step(x0.yzx, x0);
    vec3 l = (1. - g).zxy;
    vec3 i1 = min( g, l );
    vec3 i2 = max( g, l );
    vec3 x1 = x0 - i1 + C.x;
    vec3 x2 = x0 - i2 + C.y;
    vec3 x3 = x0 - D.yyy;
    i = mod(i,289.);
    vec4 p = permute( permute( permute(
    i.z + vec4(0., i1.z, i2.z, 1.))
    + i.y + vec4(0., i1.y, i2.y, 1.))
    + i.x + vec4(0., i1.x, i2.x, 1.));
    vec3 ns = .142857142857 * D.wyz - D.xzx;
    vec4 j = -49. * floor(p * ns.z * ns.z) + p;
    vec4 x_ = floor(j * ns.z);
    vec4 x = x_ * ns.x + ns.yyyy;
    vec4 y = floor(j - 7. * x_ ) * ns.x + ns.yyyy;
    vec4 h = 1. - abs(x) - abs(y);
    vec4 b0 = vec4( x.xy, y.xy );
    vec4 b1 = vec4( x.zw, y.zw );
    vec4 sh = -step(h, vec4(0));
    vec4 a0 = b0.xzyw + (floor(b0)*2.+ 1.).xzyw*sh.xxyy;
    vec4 a1 = b1.xzyw + (floor(b1)*2.+ 1.).xzyw*sh.zzww;
    vec3 p0 = vec3(a0.xy,h.x);
    vec3 p1 = vec3(a0.zw,h.y);
    vec3 p2 = vec3(a1.xy,h.z);
    vec3 p3 = vec3(a1.zw,h.w);
    vec4 norm = inversesqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;
    vec4 m = max(.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.);
    return .5 + 12. * dot( m * m * m, vec4( dot(p0,x0), dot(p1,x1),dot(p2,x2), dot(p3,x3) ) );
}void main(void)
{
    mainImage(gl_FragColor, gl_FragCoord.xy);
}