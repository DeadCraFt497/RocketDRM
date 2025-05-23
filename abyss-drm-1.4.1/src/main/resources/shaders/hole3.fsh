// thats better.
#ifdef GL_ES
precision mediump float;
#endif

uniform float time;
uniform vec2 resolution;

void main(void){
    vec2 centered_coord = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    centered_coord.y += sin(time*0.8+centered_coord.y*4.0)*0.1;
    centered_coord.y *= dot(centered_coord, centered_coord);
    float dist_from_center = length(centered_coord);
    float dist_from_center_y = length(centered_coord.y);
    float u = 6./dist_from_center_y + time * 4.;
    float v = (10./dist_from_center_y) * centered_coord.x;
    float grid = (1. - pow(sin(u) + 1., .1) + (1.0 - pow(sin(v) + 1.0, .1))) * dist_from_center_y *3.;

    float off1 = sin(fract(time*0.5)*6.28+dist_from_center*5.0)*0.4;
    float off2 = sin(fract(time*0.5)*6.28+dist_from_center_y*12.0)*0.5;

    gl_FragColor=vec4(vec3(grid)*vec3(.8+off1, .9, 1.+off2), 1.);
}