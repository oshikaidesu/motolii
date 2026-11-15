// studio.glsl: the room glass carries with it, the same wherever the glass is put: about as bright as the ground,
// with six bright strip lamps standing all round, each with a black flag at either side (how glass is photographed:
// dark hard against bright). Clear glass reads as glass only by what is around it (bright fields, black lines), so
// the glass brings its surroundings and the scene has no say. How bright it is that way, against the ground behind
// the glass (pale paper: a pale room; a black poster: a black one). Used by thick_glass.mat and far_look.mat.
float roomLamp(vec3 d) {   // 1 on a strip lamp
    return (1.0 - smoothstep(0.05, 0.07, abs(fract(atan(d.z, d.x) * 6.0 / 6.2831853) - 0.5))) * (1.0 - smoothstep(0.75, 0.9, abs(d.y)));
}
float mirroredLamp(vec3 d) {   // what the glass's faces mirror of the room: two of the lamps, soft-edged (all six, hard: a cage of white lines)
    return (1.0 - smoothstep(0.008, 0.035, abs(fract(atan(d.z, d.x) * 2.0 / 6.2831853 + 0.15) - 0.5))) * (1.0 - smoothstep(0.6, 0.9, abs(d.y)))
         + 6.0 * smoothstep(0.9975, 0.9992, dot(d, vec3(0.35, 0.86, 0.37)));   // (and one small hot lamp high up: a glint here and there)
}
float glassRoom(vec3 d) {
    float x = abs(fract(atan(d.z, d.x) * 6.0 / 6.2831853) - 0.5);    // 0 at a lamp's middle
    float flag = (1.0 - smoothstep(0.14, 0.16, x)) - (1.0 - smoothstep(0.05, 0.07, x));
    return 0.8 + 2.7 * roomLamp(d) - 0.55 * flag * (1.0 - smoothstep(0.75, 0.9, abs(d.y)));   // (0.45: the solid's sides go grey, like metal; 0.95: they melt into the ground)
}
