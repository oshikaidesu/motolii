// Spiral: dots on a spiral growing outwards, turning, a band of large dots going out and back through them
// make shape circle
// say fill ffffff
// set size 0.03
// set anchor_x -30
// set copies 170
// say script Repeater
// set js_StepX 0
// set js_Turn 1800
// set js_Size 1.006
// key rotate 0 0
// key rotate 8 -360
// say script expressions/Field.js
// set js_field_band 0.5
// set js_field_size 2.5
// key js_field_radius 0 0.2
// key js_field_radius 4 1.6
// key js_field_radius 8 0.2
// say copy_fill ffd166 ff3366 1b2fd8
