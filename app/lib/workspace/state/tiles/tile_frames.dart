// The pictures of one effect tile: sixteen of them a twelfth of a second apart, the still among them, and the names they
// are kept under beside the tile's still (the moving ones are JPEG, the full size ones PNG before they are shrunk).

/// The index of the still among the pictures: well into the motion.
const tileStill = 10;

/// How wide a tile's pictures are read. A picture drawn again under its own name is evicted at this width, or Flutter's
/// image cache shows the old one.
const tileReadWide = 256;

/// The times its pictures are drawn at.
final tileMoments = [for (var k = 0; k < 16; k++) 0.1 + k / 12];

/// Its moving pictures: home_0.jpg … home_15.jpg beside its still.
String tileFrame(String home, int k) =>
    '${home.substring(0, home.length - 4)}_$k.jpg';

/// Its pictures at full size, before they are shrunk.
String tileDrawnFrame(String home, int k) =>
    '${home.substring(0, home.length - 4)}_$k.png';
