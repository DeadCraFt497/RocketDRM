/*
 * Original shader from: https://www.shadertoy.com/view/WlycDt
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
mat2 rot(float a)
{
    float s = sin(a), c = cos(a);
    return mat2(c, s, -s, c);
}


vec3 path(float z)
{
    vec3 p = vec3(sin(z) * .5, cos(z * .5), z);
    return p;
}

vec3 fractal(vec3 p)
{
    float z = p.z * .1;
    p.z = abs(.5 - fract(z));
    float m = 100.;
    for (int i = 0; i < 10; i++)
    {
        p.xy *= rot(z);
        p = abs(p * 1.5) - 2.;
        m = min(m, abs(p.y) + .5 * abs(.5 - fract(p.x * .25 + iTime + float(i) * .1)));
    }
    m = exp(-4. * m) * 2.;
    return vec3(p.xz * 2., m) * m;
}

float de(vec3 p)
{
    p.xy -= path(p.z).xy;
    return -length(p.xy) + .25;
}

vec3 march(vec3 from, vec3 dir)
{
    float d, td = 0.;
    vec3 p, col = vec3(0);
    for (int i = 0; i < 80; i++)
    {
        p = from + dir * td;
        d = de(p);
        if (d < .001) break;
        td += d;
    }
    if (d < .1)
    {
        p -= .001 * dir;
        col = fractal(p) * exp(-.7 * td * td) * smoothstep(.3, 1., td);
    }
    return col;
}

mat3 lookat(vec3 dir, vec3 up) {
    dir = normalize(dir);
    vec3 rt = normalize(cross(dir, normalize(up)));
    return mat3(rt, cross(rt, dir), dir);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - iResolution.xy * .5) / iResolution.y;
    float t = iTime;
    vec3 from = path(t);
    vec3 fw = normalize(path(t + .5) - from);
    vec3 dir = normalize(vec3(uv, 1));
    dir = lookat(fw, vec3(0, 1, 0)) * dir;
    vec3 col = march(from, dir);
    fragColor = vec4(col,1.0);
}
// --------[ Original ShaderToy ends here ]---------- //

void main(void)
{
    mainImage(gl_FragColor, gl_FragCoord.xy);
}