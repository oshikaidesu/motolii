// Scale Assist: Alight Motion's, as bevy_alight_motion has it (resolve_parenthelper_visual_scale in src/animation/parenthelper.rs).
// Grow in one direction alone (X or Y), or in both at once (Both): wider by Amount and as much thinner as a squashed ball keeps
// its bulk, Damp easing the thinning. What it returns multiplies the layer's own Scale X and Scale Y.
// --select@assist_way:Way,both,x,y
// --track@assist_amount:Amount,0,4,1,0.01
// --track@assist_damp:Damp,1,3,1,0.01
function each(i, n, t, k) {
  const grow = k.assist_amount, damp = Math.max(1, k.assist_damp);
  if (k.assist_way === 'x') return { scale_x: grow };
  if (k.assist_way === 'y') return { scale_y: grow };
  return { scale_x: grow, scale_y: 1 / Math.max(1e-9, Math.pow(grow, 1.71) * Math.pow(damp, 1 + 2.75 * Math.pow(damp - 1, 1.93))) };
}
