// Burst: lines from a centre growing out one after another
// make shape line
// say fill ffffff
// set anchor_x -1
// set copies 24
// say script Repeater
// set js_StepX 0
// set js_Turn 360
// key size 0 0.001
// key size 0.5 1.3
// key size 6.5 1.3
// key size 7 0.001
// set stagger 0.8
// say script expressions/wave.js
// set js_wave_size 0.15
// set js_wave_phase 2.8347826
// (the Ripple of 2 it had, and what its Delay held the engine's wave back by besides: 0.8 s at a Speed of 1, over 24 copies, 0.8 x 24 / 23 of a round)
// say copy_fill ffffff ffd166 ffffff
