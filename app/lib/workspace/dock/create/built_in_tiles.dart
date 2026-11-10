// The tiles the Create shelf always has (layers, shapes, solids, lights, materials), and what each one makes.
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/workspace/dock/create/create_tile.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The groups of tiles that are always on the shelf: Layers, Shapes and Expression.
final builtInGroups = <(String, List<CreateTile>)>[
  (
    'Layers',
    [
      CreateTile(
        'Text',
        AppGlyphs.text,
        WindowTokens.toneText,
        'T',
        'Type layer',
      ),
      // The default lens is the preview's 30 degrees on Filament's 24 mm film, as the Camera tool panel shows (depth.dart _filmMm).
      CreateTile(
        'Camera',
        AppGlyphs.camera,
        WindowTokens.toneCamera,
        '⇧C',
        '3D camera, 45 mm',
      ),
      CreateTile('Null', AppGlyphs.nullObj, Grey.g76, '⇧N', 'Invisible parent'),
      CreateTile(
        'Adjustment',
        AppGlyphs.nullObj,
        Grey.g76,
        '',
        'What is put on it works on all under it',
      ),
    ],
  ),
  (
    'Shapes',
    [
      CreateTile(
        'Rectangle',
        AppGlyphs.rect,
        WindowTokens.toneShape,
        'R',
        'Rounded corners',
      ),
      CreateTile(
        'Ellipse',
        AppGlyphs.ellipse,
        WindowTokens.toneShape,
        'E',
        'Circle with ⇧',
      ),
      CreateTile(
        'Polygon',
        AppGlyphs.polygon,
        WindowTokens.toneShape,
        '',
        'Sides · Roundness',
      ),
      CreateTile(
        'Star',
        AppGlyphs.star,
        WindowTokens.toneShape,
        '',
        'Points · Inner radius',
      ),
      CreateTile(
        'Line',
        AppGlyphs.line,
        WindowTokens.toneShape,
        'L',
        'Open path',
      ),
    ],
  ),
  (
    // Every JS file that goes on a layer and moves its values comes after Empty (expressions.dart expressionsOf).
    'Expression',
    [
      CreateTile(
        'Empty',
        AppGlyphs.plus,
        InspectorSkin.tonePlace,
        '',
        'An empty expression on the picked thing (nothing picked: on a new board): write or paste each() into its card\'s code',
      ),
    ],
  ),
];

/// The engine's own 3D shapes. A tile is created by its kind, then its file or shape (see [layerOfTile]).
final solidGroup = (
  '3D',
  [
    CreateTile(
      'Ring',
      AppGlyphs.radial,
      WindowTokens.toneShape,
      '',
      'A solid ring',
    ),
    CreateTile(
      'Gem',
      AppGlyphs.polygon,
      WindowTokens.toneShape,
      '',
      'A cut solid',
    ),
    CreateTile(
      'Cube',
      AppGlyphs.rect,
      WindowTokens.toneShape,
      '',
      'A round-edged cube',
    ),
    CreateTile(
      'Floor',
      AppGlyphs.rect,
      WindowTokens.toneShape,
      '',
      'A wide flat floor that takes shadows',
    ),
    CreateTile('Ball', AppGlyphs.ellipse, WindowTokens.toneShape, '', 'A ball'),
  ],
);

/// Filament's own lights. They are layers of the project: placed and rotated like any other layer, and they light the solid layers.
final lightGroup = (
  'Light',
  [
    CreateTile(
      'Sun',
      AppGlyphs.light,
      WindowTokens.toneCamera,
      '',
      'Light from one way, everywhere',
    ),
    CreateTile(
      'Point',
      AppGlyphs.light,
      WindowTokens.toneCamera,
      '',
      'Light from a point, all round',
    ),
    CreateTile(
      'Spot',
      AppGlyphs.light,
      WindowTokens.toneCamera,
      '',
      'A cone of light',
    ),
  ],
);

/// Materials: Filament's own and the engine's, under the names a user knows (the engine's word is the shading value, see doc.h doc_material).
///
/// A material goes on the picked layer in place of the one it has, one at a time. Any visible layer can wear one: a flat layer
/// wears it on its own plane, and an image layer takes its color. With nothing picked, a ball wearing the material is created.
/// Materials are in Create, not among the colors. Each tile shows a ball wearing the material (material_tiles.dart).
final materialGroup = (
  'Material',
  [
    CreateTile(
      'Lit',
      AppGlyphs.ellipse,
      WindowTokens.toneShape,
      '',
      'Filament\'s lit surface: its colour, metal, rough, a clear coat',
    ),
    CreateTile(
      'Cloth',
      AppGlyphs.ellipse,
      WindowTokens.toneShape,
      '',
      'Soft, no sharp highlight, a sheen at its rim',
    ),
    CreateTile(
      'Subsurface',
      AppGlyphs.ellipse,
      WindowTokens.toneShape,
      '',
      'Light goes into it and comes out, as in wax or skin',
    ),
    CreateTile(
      'Glass',
      AppGlyphs.radial,
      WindowTokens.toneShape,
      '',
      'Thick glass: bends and tints what lies behind it',
    ),
    CreateTile(
      'Filament glass',
      AppGlyphs.radial,
      WindowTokens.toneShape,
      '',
      'Filament\'s own glass: bends what is behind, a thin film\'s rainbow',
    ),
    CreateTile(
      'Lacquer',
      AppGlyphs.ellipse,
      WindowTokens.toneShape,
      '',
      'Its colour under a hard clear coat',
    ),
    CreateTile(
      'Bubble',
      AppGlyphs.radial,
      WindowTokens.toneShape,
      '',
      'Nearly clear, a bright rim',
    ),
  ],
);

/// Tile name to the shading value it sets.
const shadingOfTile = {
  'Lit': 'lit',
  'Cloth': 'cloth',
  'Subsurface': 'subsurface',
  'Glass': 'glass',
  'Filament glass': 'filament_glass',
  'Lacquer': 'lacquer',
  'Bubble': 'bubble',
};

/// The layer kinds that are visible, and so can wear a material.
const kindsThatWear = {'film', 'picture', 'text', 'shape', 'solid'};

/// Tile name to the (kind, shape) of the layer it creates.
final layerOfTile = {
  'Text': ('text', defaultTextFont),
  // A flat color as large as the preview; the engine builds it that size.
  'Solid': ('shape', 'solid'),
  'Rectangle': ('shape', 'rect'),
  'Ellipse': ('shape', 'circle'),
  'Polygon': ('shape', 'polygon'),
  'Star': ('shape', 'star'),
  'Line': ('shape', 'line'),
  // Invisible: other layers can be parented to it.
  'Null': ('shape', 'null'),
  // The nearest camera that is on is the one the preview looks through.
  'Camera': ('camera', 'camera'),
  'Ring': ('solid', 'ring'),
  'Gem': ('solid', 'gem'),
  'Cube': ('solid', 'cube'),
  'Floor': ('solid', 'cube'),
  'Ball': ('solid', 'ball'),
  'Sun': ('light', 'sun'),
  'Point': ('light', 'point'),
  'Spot': ('light', 'spot'),
};

/// Transform values set on a layer right after its tile creates it, in the same undo step.
///
/// Floor follows Cinema 4D's Floor object: a Cube laid flat under the preview, because a flat Rectangle is unlit and takes no shadow.
/// Sun shines from above and in front, as After Effects' new light looks at the middle of the composition from there.
/// With no rotation a Sun would shine along the floor and light nothing on it.
const startValuesOfTile = <String, Map<String, double>>{
  'Floor': {'scale_x': 12, 'scale_y': .01, 'scale_z': 12, 'y': -.48},
  'Sun': {'rotate_x': -60, 'rotate_y': 35},
};

/// Values set on the picked layer when the Repeater is first added to it (its parameters js_StepX and js_Size).
/// They lay the copies out in a row, side by side and a little smaller each time, as the tile did before it was an expression.
/// Keyed by the expression's name.
const firstValuesOfExpression = <String, Map<String, double>>{
  'Repeater': {'js_StepX': 1.3, 'js_Size': .92},
};
