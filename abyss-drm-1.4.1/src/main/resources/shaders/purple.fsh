#ifdef GL_ES
precision mediump float;
#endif

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

void main(void)
{
    vec2 uPos = (gl_FragCoord.xy / resolution.xy);

    uPos.x -= 0.95;
    uPos.y -= 0.95;

    vec3 color = vec3(0.0);
    float vertColor = 0.0;

    float t = time * (0.9);

    float intensity = 2.0;

    for (float i = 0.0; i < 15.0; i++)
    {
        float j = i / 10.0;

        uPos.y += sin((uPos.x + j) * (intensity + 1.0) + t + intensity / 5.0) * 0.01;
        float fTempY = abs(1.0 / (uPos.y + j) / 500.0);

        color += vec3(fTempY * (15.0 - intensity) / 10.0, fTempY * intensity / 10.0, pow(fTempY, 0.99) * 1.9);

        uPos.x += sin((uPos.y + j) * (intensity + 1.0) + t + 5.0 / intensity) * 0.01;
        float fTempX = abs(1.0 / (uPos.x + j) / 190.0);

        color += vec3( fTempX * intensity / 10.0);
    }
    vec4 color_final = vec4(color, 1.0);

    gl_FragColor = color_final;
}