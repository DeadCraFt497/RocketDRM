#ifdef GL_ES
precision mediump float;
#endif

#extension GL_OES_standard_derivatives : enable

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;


//global animation speed
#define animSpeed 0.05

//alternative Z fold anim
//#define advFold

#define Phi (0.5*(1.+sqrt(5.0)))
vec3 n1 = normalize(vec3(-Phi,Phi-1.0,1.0));
vec3 n2 = normalize(vec3(1.0,-Phi,Phi+1.0));
vec3 n3 = normalize(vec3(0.0,0.0,-1.0));
mat4 m;



//std matrix ------------------

mat4 rotationMatrix(vec3 v, float angle)
{
    float c = cos(radians(angle));
    float s = sin(radians(angle));

    return mat4(c + (1.0 - c) * v.x * v.x, (1.0 - c) * v.x * v.y - s * v.z, (1.0 - c) * v.x * v.z + s * v.y, 0.0,
    (1.0 - c) * v.x * v.y + s * v.z, c + (1.0 - c) * v.y * v.y, (1.0 - c) * v.y * v.z - s * v.x, 0.0,
    (1.0 - c) * v.x * v.z - s * v.y, (1.0 - c) * v.y * v.z + s * v.x, c + (1.0 - c) * v.z * v.z, 0.0,
    0.0, 0.0, 0.0, 1.0);
}
mat4 translate(vec3 v) {
    return mat4(1.0,0.0,0.0,0.0,
    0.0,1.0,0.0,0.0,
    0.0,0.0,1.0,0.0,
    v.x,v.y,v.z,1.0);
}
mat4 scale4(float s) {
    return mat4(s,0.0,0.0,0.0,
    0.0,s,0.0,0.0,
    0.0,0.0,s,0.0,
    0.0,0.0,0.0,1.0);
}

// polynomial smooth min (k = 0.1);
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

//sdf --------------------------

float sdPlane( vec3 p )
{
    return p.y;
}

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float polyhedra(vec3 z)
{
    const int steps = 2;

    //timespeed
    float ts = time *animSpeed;
    float a = 0.3, a2 = 0.6;

    float scale = 2.0;
    float size = 0.66;

    float ang1 = sin(ts *0.01)*120.0;
    float ang2 = 64.0;

    vec3 rot1;
    rot1.x = sin(ts)*a;
    rot1.z = cos(ts)*a;
    rot1.y = sin(0.5 +ts *0.25)*a;

    vec3 rot2;
    rot2.x = sin(ts *0.25) *a2;
    rot2.z = cos(ts *0.5) *a2;
    rot2.y = sin(0.5 +ts *0.15)*a2;


    vec3 offset;

    offset.x = sin(ts *2.0) *0.1;
    offset.z = cos(ts *1.9) *0.1;
    offset.y = sin(0.5 +ts *1.8)*0.1;

    vec3 plNormal = normalize(vec3(1.0,-0.1, 0.55));

    mat4 fracRotation2 = rotationMatrix(normalize(rot2), ang1);
    mat4 fracRotation1 = rotationMatrix(normalize(rot1), ang2);
    m =  fracRotation2 * translate(offset) * scale4(scale)
    * translate(-offset) * fracRotation1;

    float s=1.0;
    float t;

    //folds
    float dmin = -10000.0;
    for(int i=0; i<steps; i++)
    {
        z = abs(z);
        t=dot(z,n1); if (t>0.0) { z-=2.0*t*n1; }
        t=dot(z,n2); if (t>0.0) { z-=2.0*t*n2; }
        z = abs(z);
        t=dot(z,n1); if (t>0.0) { z-=2.0*t*n1; }
        t=dot(z,n2); if (t>0.0) { z-=2.0*t*n2; }
        z = abs(z);

        //combine
        dmin=max(dmin, s*dot(z-vec3(size,0.0,0.0),plNormal));
        z = (m*vec4(z,1.0)).xyz;  s /= scale;

        float saw = mod(z.y,0.2);
        z.y = mix(z.y, saw, sin(ts));
    }

        #ifdef advFold
    z.x = mod(z.z,1.5);
    #endif

    return dmin;
}

//----------------------------------------------------------------------

vec2 map( in vec3 pos )
{
    vec2 res = vec2 (polyhedra(pos),2.5) *0.9;

    return res;
}

vec2 castRay( in vec3 ro, in vec3 rd )
{
    float tmin = 1.0;
    float tmax = 20.0;
    float precis = 0.002;
    float t = tmin;
    float m = -1.0;

    //raymarch
    for (int i=0; i<50; i++)
    {
        vec2 res = map( ro +rd*t );
        if (res.x < precis || t > tmax) break;
        t += res.x;
        m = res.y;
    }

    if (t > tmax) m = -1.0;
    return vec2( t, m );
}


float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<16; i++ )
    {
        float h = map( ro + rd*t ).x;
        res = min( res, 8.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );

}

vec3 calcNormal( in vec3 pos )
{
    vec3 eps = vec3( 0.001, 0.0, 0.0 );
    vec3 nor = vec3(
    map(pos+eps.xyy).x - map(pos-eps.xyy).x,
    map(pos+eps.yxy).x - map(pos-eps.yxy).x,
    map(pos+eps.yyx).x - map(pos-eps.yyx).x );
    return normalize(nor);
}

float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );
}


vec3 render( in vec3 ro, in vec3 rd )
{
    //bg
    vec3 col = vec3(0.12, 0.2, 0.25)*0.35 +rd.y*0.1;

    //march
    vec2 res = castRay(ro,rd);
    float t = res.x;
    float m = res.y;


    if (m > -0.5)
    {
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal( pos );
        vec3 ref = reflect( rd, nor );
        col = 0.45 + 0.3*sin( vec3(0.05,0.08,0.10)*(m-1.0) );
        //col = vec3(0.15,0.15,0.15);

        if( m<1.5 )
        {

            float f = mod( floor(5.0*pos.z) + floor(5.0*pos.x), 2.0);
            col = 0.4 + 0.1*f*vec3(1.0);
        }

        // lighitng
        float occ = calcAO( pos, nor );
        vec3  lig = normalize( vec3(-0.6, 0.7, -0.5) );

        float amb = clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        float bac = clamp( dot( nor, normalize(vec3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);
        float dom = smoothstep( -0.1, 0.1, ref.y );
        float fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );
        float spe = pow(clamp( dot( ref, lig ), 0.0, 1.0 ),16.0);

        dif *= softshadow( pos, lig, 0.02, 2.5 );
        dom *= softshadow( pos, ref, 0.02, 2.5 );

        vec3 lin = vec3(0.0);
        lin += 1.20*dif*vec3(1.00,0.85,0.55);
        lin += 1.20*spe*vec3(1.00,0.85,0.55)*dif;
        lin += 0.20*amb*vec3(0.50,0.70,1.00)*occ;
        lin += 0.30*dom*vec3(0.50,0.70,1.00)*occ;
        lin += 0.30*bac*vec3(0.25,0.25,0.25)*occ;
        lin += 0.40*fre*vec3(1.00,1.00,1.00)*occ;
        col = col*lin;

        float base = (1.0-amb) + (1.0-fre);
        float g = pow(base,0.2);
        g = clamp(g,0.1,1.0);
        vec3 glow = vec3(0.5-g, 0.99-g, 1.0-g)*1.0;

        col = mix( col, vec3(0.8,0.9,1.0), 1.0-exp( -0.002*t*t ) );
        col += glow;

    }

    return vec3( clamp(col,0.0,1.0) );
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main( void )
{
    vec2 q = gl_FragCoord.xy/resolution.xy;
    vec2 p = -1.0+2.0*q;
    p.x *= resolution.x/resolution.y;
    vec2 mo = mouse.xy/resolution.xy;

    float atime = 15.0 + time *5.0;

    // camera
    float sh = 2.5;
    vec3 ro = vec3( sh*cos(0.1*atime + 6.0*mo.x), 2.0*mo.y, sh*sin(0.1*time + 6.0*mo.x) );
    vec3 ta = vec3(0.0, 0.0, 0.0);//vec3( -0.5, -0.4, 0.5 );

    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );

    // ray direction
    vec3 rd = ca * normalize( vec3(p.xy,2.0) );

    // render
    vec3 col = render( ro, rd );

    //gamma
    col = pow( col, vec3(0.4545) );

    gl_FragColor=vec4( col, 1.0 );
}