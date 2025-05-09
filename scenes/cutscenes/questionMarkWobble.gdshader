shader_type canvas_item;

uniform float amplitude  : hint_range(0,1)  = 0.3;
uniform float frequency  : hint_range(0,20) = 8.0;
uniform vec2  rect_size;  // set from GDScript

void vertex() {
    // center pivot
    vec2 p = VERTEX - rect_size * 0.5;

    // compute wobble angle
    float ang = sin(TIME * frequency) * amplitude;

    // rotate p by ang
    mat2 rot = mat2(
      vec2(cos(ang), -sin(ang)),
      vec2(sin(ang),  cos(ang))
    );
    p = rot * p;

    // back to original origin
    VERTEX = p + rect_size * 0.5;
}