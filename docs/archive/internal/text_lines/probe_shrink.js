// Probe: every copy at a size and a turn, to see what it scales and turns about
// --track@size:Size,0,2,1,0.01
// --track@turn:Turn,-180,180,0,1
function each(i, n, t, k) { return { size: k.size, rotate: k.turn }; }
