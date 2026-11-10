// Weave: short lines across and down in turn, turning where a round field passes over them
// make shape line
// say fill ffffff
// set size 0.26
// set copies 135
// say script Repeater
// set js_Columns 15
// set js_Rotate 90
// set js_StepX 0.36
// set js_StepY -0.36
// say script expressions/Field.js
// set js_field_radius 1.4
// set js_field_rotate 90
// key js_field_x 0 -3
// key js_field_x 4 3
// key js_field_x 8 -3
// say copy_fill ffffff 3366ff
