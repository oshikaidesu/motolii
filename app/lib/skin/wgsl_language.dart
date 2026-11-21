// WGSL + WESL UI attributes (@range, @color, @toggle, @group, @label, @auto)
// highlighter definition for re_highlight.
import 'package:re_highlight/re_highlight.dart' show Mode;

final Mode langWgsl = Mode(
  name: 'WGSL',
  keywords: {
    'keyword':
        'alias break case const const_assert continue continuing default '
        'diagnostic discard else enable false fn for if let loop override '
        'requires return struct switch true var while',
    'type':
        'bool f16 f32 i32 u32 atomic ptr array sampler sampler_comparison '
        'vec2 vec3 vec4 vec2f vec3f vec4f vec2i vec3i vec4i vec2u vec3u vec4u '
        'vec2h vec3h vec4h mat2x2 mat2x3 mat2x4 mat3x2 mat3x3 mat3x4 mat4x2 '
        'mat4x3 mat4x4 mat2x2f mat3x3f mat4x4f texture_1d texture_2d '
        'texture_2d_array texture_3d texture_cube texture_cube_array '
        'texture_multisampled_2d texture_storage_1d texture_storage_2d '
        'texture_storage_2d_array texture_storage_3d texture_depth_2d '
        'uniform storage private workgroup function read write read_write',
    'built_in':
        'abs acos acosh all any asin asinh atan atan2 atanh bitcast ceil clamp '
        'cos cosh countLeadingZeros countOneBits countTrailingZeros cross '
        'degrees determinant distance dot exp exp2 extractBits faceForward '
        'firstLeadingBit firstTrailingBit floor fma fract frexp insertBits '
        'inverseSqrt ldexp length log log2 max min mix modf normalize pow '
        'quantizeToF16 radians reflect refract reverseBits round saturate '
        'select sign sin sinh smoothstep sqrt step tan tanh textureDimensions '
        'textureGather textureLoad textureNumLayers textureNumLevels '
        'textureSample textureSampleBias textureSampleCompare '
        'textureSampleGrad textureSampleLevel textureStore transpose trunc '
        'workgroupBarrier storageBarrier',
  },
  contains: [
    Mode(className: 'comment', begin: r'//', end: r'$'),
    Mode(className: 'comment', begin: r'/\*', end: r'\*/'),
    Mode(className: 'string', begin: '"', end: '"'),
    // WGSL / WESL attributes such as @range(...), @color(...), @fragment, @binding(0).
    Mode(className: 'meta', begin: r'@[A-Za-z_][A-Za-z0-9_]*'),
    Mode(
      className: 'number',
      begin: r'\b(?:0[xX][0-9a-fA-F]+[iu]?|(?:\d+\.\d*|\.\d+)(?:[eE][+-]?\d+)?[fh]?|\d+(?:[eE][+-]?\d+[fh]?|[iufh]))\b|\b\d+\b',
    ),
  ],
);
