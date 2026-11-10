// Field dots: a grid of dots swelling where a round field passes over them
// make shape circle
// say fill ffffff
// set size 0.06
// set copies 312
// say script Repeater
// set js_Columns 24
// set js_StepX 0.24
// set js_StepY -0.24
// say script expressions/wave.js
// set js_wave_y 0.015
// set js_wave_noise 1
// set js_wave_speed 0.5
// say script expressions/Field.js
// set js_field_radius 1.4
// set js_field_size 1.2
// set js_field_push 0.6
// key js_field_x 0 -1.8
// key js_field_x 4 1.8
// key js_field_x 8 -1.8
// say copy_fill ffffff ff3366
