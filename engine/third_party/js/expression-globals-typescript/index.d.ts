export declare type Points = Vector2D[];
export declare type Vector2D = [x: number, y: number];
export declare type Vector3D = [x: number, y: number, z: number];
export declare type Vector = Vector2D | Vector3D;
export declare type Color = [r: number, g: number, b: number, a: number];
export declare type NumericValue = number | number[] | Vector | Color;
declare type MathReturn<A extends NumericValue, B extends NumericValue> = A extends number[] ? A : B extends number[] ? B : A extends number ? B extends number ? number : Error : Error;
export interface PathValue {
    className: "Path Object";
}
export declare type SourceData = any[];
/**
 * Keyframe objects, which can be accessed via the property method `property.key()`
 */
export declare class Key<ValueType extends Value> {
    /**
     * The value of the keyframe
     */
    readonly value: ValueType;
    /**
     * The location of the keyframe in time
     */
    readonly time: number;
    /**
     * The index of the keyframe, e.g. The `1`st keyframe on the property. Starts from 0.
     */
    readonly index: number;
    constructor(keyValue: ValueType);
}
export declare class Project {
    /**
     * The platform-specific absolute file path, including the project file name. If the project has not been saved, it returns an empty string.
     */
    readonly fullPath: string;
    /**
     * The color depth of the project in bits per channel (bpc), as set in Project Settings > Color Management
     */
    readonly bitsPerChannel: "8" | "16" | "32";
    /**
     * The state of the Blend Colors Using 1.0 Gamma option in Project Settings > Color Management
     */
    readonly linearBlending: boolean;
}
export interface MarkerParam {
    [id: string]: Value;
}
/**
 * Composition or Layer marker objects
 */
export declare class MarkerKey {
    /**
     * Duration, in seconds, of marker.
     */
    readonly duration: number;
    /**
     * Contents of Comment field in marker dialog box.
     */
    readonly comment: string;
    /**
     * Contents of Chapter field in marker dialog box.
     */
    readonly chapter: string;
    /**
     * Contents of URL field in marker dialog box.
     */
    readonly url: string;
    /**
     * Contents of Frame Target field in marker dialog box.
     */
    readonly frameTarget: string;
    /**
     * Setting for cue point type in marker dialog box. True for Event; false for Navigation.
     */
    readonly eventCuePoint: boolean;
    /**
     * Contents of cue point Name field in marker dialog box.
     */
    readonly cuePointName: string;
    /**
     * Contents of Parameter Name and Parameter Value fields in marker dialog box.
  
    For example, if you have a parameter named “background color”, then you can use the following expression to access its value at the nearest marker:  thisComp.marker.nearestKey(time).parameters["background color"]
     */
    readonly parameters: MarkerParam;
    /**
     * Whether the marker represents a protected region
     */
    readonly protectedRegion: boolean;
    /**
     * The location of the marker in time
     */
    readonly time: number;
    /**
     * The index of the marker
     */
    readonly index: number;
}
export declare class MarkerProperty {
    /**
     * The total number of composition markers in the composition.
     */
    readonly numKeys: number;
    /**
     * @returns The `Marker` object with the specified name or index
     * @param indexOrName Either the index or name (the value of the commend field) of the marker
     */
    key(indexOrName: number | string): MarkerKey;
    /**
     * @returns The marker that is nearest in time to `t`
     * @param t Time value to get the marker closest to
     */
    nearestKey(t: number): MarkerKey;
}
export declare class Comp {
    /**
     * The name of the composition.
     */
    readonly name: string;
    /**
     * The number of layers in the composition.
     */
    readonly numLayers: number;
    /**
     * The Camera object for the camera through which the composition is rendered at the current frame. This camera is not necessarily the camera through which you are looking in the Composition panel.
     */
    readonly activeCamera: Camera;
    /**
     * The marker property group object
     */
    readonly marker?: MarkerProperty;
    /**
     * The composition width in pixels
     */
    readonly width: number;
    /**
     * The composition height in pixels
     */
    readonly height: number;
    /**
     * The composition duration in seconds
     */
    readonly duration: number;
    /**
     * Whether the timecode is in drop-frame format
     */
    readonly ntscDropFrame: boolean;
    /**
     * The composition start time in seconds
     */
    readonly displayStartTime: number;
    /**
     * The duration of a frame, in seconds
     */
    readonly frameDuration: number;
    /**
     * The shutter-angle of the composition, in degrees
     */
    readonly shutterAngle: number;
    /**
     * The background color of the composition
     */
    readonly bgColor: Color;
    /**
     * The pixel aspect ratio of the composition
     */
    readonly pixelAspect: number;
    /**
     * Gets a layer in the composition
     * @param indexOrOtherLayer The index or name of the layer to return, or a Layer object if using the relative index
     * @param relIndex Used when a layer is provided for the first input, the relative index from the given Layer
     * @returns The requested Layer object
     */
    layer(index: number): Layer;
    layer(name: string): Layer;
    layer(otherLayer: Layer, relativeIndex: number): Layer;
}
/**
 * Groups of properties such as "Transform"
 */
export declare class PropertyGroup {
    /**
     * The name of the property group, e.g. `"Transform"`
     */
    readonly name: string;
    /**
     * The number of properties in the group
     */
    readonly numProperties: number;
    constructor(groupName: string);
}
export declare type Value = NumericValue | string | boolean | PathValue;
export declare class Property<PropertyValueType extends Value> {
    readonly value: PropertyValueType;
    readonly name: string;
    /**
     * The temporal velocity value at the current time. For spatial properties, such as Position, it returns the tangent vector value. The result is the same dimension as the property.
     */
    readonly velocity: PropertyValueType;
    /**
     * A 1D, positive speed value equal to the speed at which the property is changing at the default time. This element can be used only for spatial properties.
     */
    readonly speed: PropertyValueType;
    constructor(value: PropertyValueType, name?: string);
    /**
     * The number of keyframes on the property
     */
    readonly numKeys: number;
    /**
     * The index number of the property in it's property group
     */
    readonly propertyIndex: number;
    /**
     * @returns The keyframe at the specified index on the property
     * @param index The index of the keyframe to return (e.g. the `1`st keyframe)
     */
    key(index: number): Key<PropertyValueType>;
    /**
     * @returns The marker that is nearest in time to `t`
     * @param t Time value to get the marker closest to
     */
    nearestKey(time: number): Key<PropertyValueType>;
    /**
     * @returns The group of properties (`PropertyGroup` object) relative to the property of which the expression is written
     * @param countUp The number of levels in the property hierarchy to ascend, e.g. `countUp = 1` will return the parent `PropertyGroup`.
     */
    propertyGroup(countUp: number): PropertyGroup;
    /**
     * Loops a segment of time that is measured from the first keyframe on the layer forward toward the Out point of the layer. The loop plays from the In point of the layer.
     * @param type `"cycle"`: (default) Repeats the specified segment.
     * `"pingpong"`: Repeats the specified segment, alternating between forward and backward.
     * `"offset"`: Repeats the specified segment, but offsets each cycle by the difference in the value of the property at the start and end of the segment, multiplied by the number of times the segment has looped.
     * `"continue"`: Does not repeat the specified segment, but continues to animate a property based on the velocity at the first or last keyframe.
     * @param numKeyframes determines what segment is looped: The segment looped is the portion of the layer from the first keyframe to the numKeyframes+1 keyframe. The default value of 0 means that all keyframes loop
     */
    loopIn(type?: loopType, numKeyframes?: number): PropertyValueType;
    /**
     * Loops a segment of time that is measured from the last keyframe on the layer back toward the In point of the layer. The loop plays until the Out point of the layer.
     * @param type `"cycle"`: (default) Repeats the specified segment.
     * `"pingpong"`: Repeats the specified segment, alternating between forward and backward.
     * `"offset"`: Repeats the specified segment, but offsets each cycle by the difference in the value of the property at the start and end of the segment, multiplied by the number of times the segment has looped.
     * `"continue"`: Does not repeat the specified segment, but continues to animate a property based on the velocity at the first or last keyframe.
     * @param numKeyframes determines what segment is looped: The segment looped is the portion of the layer from the last keyframe to the `thisProperty.numKeys - numKeyframes` keyframe. The default value of 0 means that all keyframes loop
     */
    loopOut(type?: loopType, numKeyframes?: number): PropertyValueType;
    /**
     * Loops a segment of time that is measured from the first keyframe on the layer forward toward the Out point of the layer. The loop plays from the In point of the layer.
     * @param type `"cycle"`: (default) Repeats the specified segment.
     * `"pingpong"`: Repeats the specified segment, alternating between forward and backward.
     * `"offset"`: Repeats the specified segment, but offsets each cycle by the difference in the value of the property at the start and end of the segment, multiplied by the number of times the segment has looped.
     * `"continue"`: Does not repeat the specified segment, but continues to animate a property based on the velocity at the first or last keyframe.
     * @param duration The number of composition seconds in a segment to loop; the specified range is measured from the first keyframe
     */
    loopInDuration(type?: loopType, duration?: number): PropertyValueType;
    /**
     * Loops a segment of time that is measured from the last keyframe on the layer back toward the In point of the layer. The loop plays until the Out point of the layer.
     * @param type `"cycle"`: (default) Repeats the specified segment.
     * `"pingpong"`: Repeats the specified segment, alternating between forward and backward.
     * `"offset"`: Repeats the specified segment, but offsets each cycle by the difference in the value of the property at the start and end of the segment, multiplied by the number of times the segment has looped.
     * `"continue"`: Does not repeat the specified segment, but continues to animate a property based on the velocity at the first or last keyframe.
     * @param duration The number of composition seconds in a segment to loop; the specified range is measured from the last keyframe backwards.
     */
    loopOutDuration(type?: loopType, duration?: number): PropertyValueType;
    /**
     * @returns The temporal velocity value at the specified time. For spatial properties, such as Position, it returns the tangent vector value. The result is the same dimension as the property.
     * @param time The composition time in seconds to get the velocity at
     */
    velocityAtTime(time: number): PropertyValueType;
    /**
     * @returns  A 1D, positive speed value equal to the speed at which the property is changing at the specified time. This element can be used only for spatial properties.
     * @param time The composition time in seconds to get the speed at
     */
    speedAtTime(time: number): PropertyValueType;
    /**
     * Returns the value for the property at the specified time
     * @param time THe composition time in seconds to get the value at
     */
    valueAtTime(time: number): PropertyValueType;
    /**
     * Modifies the property value randomly over time.
     * @param freq The rate at which the value changes in wiggles per second
     * @param amp How much the value should change, in units of the original property value (e.g. `1` by 100% of the original value)
     * @param octaves How much detail the wiggle has, which is driven by the number of "octaves" of noise to multiply together. Higher values will have more detail
     * @param amp_mult The amount the given amplitude is multiplied by for each octave, which controls the falloff of the upper harmonics ("octaves").
     * @param time The time at which the value is sampled for use within the wiggle
     */
    wiggle(freq: number, amp: number, octaves?: number, amp_mult?: number, time?: number): PropertyValueType;
    /**
     * Samples the property value at a time which is wiggled
     * @param freq The rate at which the value changes in wiggles per second
     * @param amp How much the value should change, in units of the original property value (e.g. `1` by 100% of the original value)
     * @param octaves How much detail the wiggle has, which is driven by the number of "octaves" of noise to multiply together. Higher values will have more detail
     * @param amp_mult The amount the given amplitude is multiplied by for each octave, which controls the falloff of the upper harmonics ("octaves").
     * @param time The time at which the value is sampled for use within the wiggle
     */
    temporalWiggle(freq: number, amp: number, octaves?: number, amp_mult?: number, time?: number): PropertyValueType;
    /**
     * Smooths the property values over time, converting large, brief deviations in the value to smaller, more evenly distributed deviations. This smoothing is accomplished by applying a box filter to the value of the property at the specified time.
     * @param width The range of time (in seconds) over which the filter is averaged.
     * @param samples The number of discrete samples evenly spaced over time; use a larger value for greater smoothness (but decreased performance). Generally, you’ll want samples to be an odd number so that the value at the current time is included in the average.
     */
    smooth(width?: number, samples?: number, time?: number): PropertyValueType;
}
export declare class PathProperty extends Property<PathValue> {
    /**
     * Creates a path object from a set of points and tangents.
     * @param points An array of number pair arrays representing x,y coordinates of the path points. The array length must be at least 1, and can be of any greater length.
     * @param inTangents An array containing number pair arrays representing the `[x,y]` offset coordinates of the tangent handles to the path points. Required unless no parameters are passed (i.e., `createPath()`). The array length must be the same as points, or you can pass an empty array (`[]`), which will assume the same length as points and `[0,0]` for all tangents.
     * @param outTangents See `inTangents`
     * @param isClosed Determines if the mask is closed. If true, the last point will be connected to the first point.
     */
    createPath(points?: Points, inTangents?: Points | [], outTangents?: Points | [], is_closed?: boolean): PathValue;
    /**
     * @returns Whether a path is closed (the last point connected to the first)
     */
    isClosed(): boolean;
    /**
     * Retrieves the points array for a path
     * @param time The time at which to sample the path
     */
    points(time?: number): Points;
    /**
     * Retrieves the path's in tangent point array
     * @param time The time at which to sample the path
     */
    inTangents(time?: number): Points;
    /**
     * Retrieves the path's out tangent point array
     * @param time The time at which to sample the path
     */
    outTangents(time?: number): Points;
    /**
     * Get the x,y coordinates of an arbitrary point along a path.
     * @param percentage How far along the path to get the point, between 0 and 1.
     * @param time The time at which to sample the path
     */
    pointOnPath(percentage?: number, time?: number): Vector2D;
    /**
     * Get the calculated x,y coordinates of the outgoing tangent handle for an arbitrary point along a path.
     * @param percentage How far along the path to get the point, between 0 and 1.
     * @param time The time at which to sample the path
     */
    tangentOnPath(percentage?: number, time?: number): Vector2D;
    /**
     * Get the calculated x,y coordinates of the normal for an arbitrary point along a path.
     * @param percentage How far along the path to get the point, between 0 and 1.
     * @param time The time at which to sample the path
     */
    normalOnPath(percentage?: number, time?: number): Vector2D;
    constructor(value?: PathValue);
}
export declare type loopType = "cycle" | "pingpong" | "offset" | "continue";
export declare class Transform extends PropertyGroup {
    constructor();
    /**
     * The opacity of the layer, as a percentage.
     */
    readonly opacity: Property<number>;
    /**
     * The anchor point value of the layer in the coordinate system of the layer (layer space).
     */
    readonly anchorPoint: Property<Vector>;
    /**
     * The position value of the layer, in world space if the layer has no parent. If the layer has a parent, it returns the position value of the layer in the coordinate system of the parent layer (in the layer space of the parent layer).
     */
    readonly position: Property<Vector>;
    /**
     * The x position value of the layer, in world space if the layer has no parent. If the layer has a parent, it returns the position value of the layer in the coordinate system of the parent layer (in the layer space of the parent layer).
     */
    readonly xPosition: Property<number>;
    /**
     * The y position value of the layer, in world space if the layer has no parent. If the layer has a parent, it returns the position value of the layer in the coordinate system of the parent layer (in the layer space of the parent layer).
     */
    readonly yPosition: Property<number>;
    /**
     * The z position value of the layer, in world space if the layer has no parent. If the layer has a parent, it returns the position value of the layer in the coordinate system of the parent layer (in the layer space of the parent layer).
     */
    readonly zPosition: Property<number>;
    /**
     * The scale value of the layer, expressed as a percentage.
     */
    readonly scale: Property<Vector>;
    /**
     * Returns the rotation value of the layer in degrees. For a 3D layer, it returns the z rotation value in degrees.
     */
    readonly rotation: Property<number>;
    /**
     * Returns the 3D orientation value, in degrees, for a 3D layer.
     */
    readonly orientation?: Property<Vector3D>;
    /**
     * Returns the x rotation value, in degrees, for a 3D layer.
     */
    readonly rotationX?: Property<number>;
    /**
     * Returns the y rotation value, in degrees, for a 3D layer.
     */
    readonly rotationY?: Property<number>;
    /**
     * Returns the z rotation value, in degrees, for a 3D layer.
     */
    readonly rotationZ?: Property<number>;
}
export declare class TextStyle {
    /**
     * Font size of the style
     */
    fontSize: number;
    /**
     * Set the font size for a style
     * @param fontSize Font size in pixels
     * @param s Start index
     * @param n Number of characters
     */
    setFontSize(fontSize: number, s?: number, n?: number): TextStyle;
    /**
     * Font of the style
     */
    font: string;
    /**
     * Set the font for a style
     * @param font The typeface to set
     * @param s Start index
     * @param n Number of characters
     */
    setFont(font: string, s?: number, n?: number): TextStyle;
    /**
     * Set the text content of a sourceText property, used when you need to return a `style` object *and* set the `value`
     * @param text The string to set
     */
    setText(text: string): TextStyle;
    /**
     * Whether faux bold is enabled for a style
     */
    isFauxBold: boolean;
    /**
     * Set the faux bold property for a style
     * @param s Start index
     * @param n Number of characters
     */
    setFauxBold(isFauxBold: boolean, s?: number, n?: number): TextStyle;
    /**
     * Whether faux italic is enabled
     */
    isFauxItalic: boolean;
    /**
     * Set the faux italic property for a style
     * @param s Start index
     * @param n Number of characters
     */
    setFauxItalic(isFauxItalic: boolean, s?: number, n?: number): TextStyle;
    /**
     * Whether all caps is enabled for a style
     */
    isAllCaps: boolean;
    /**
     * Set the all caps property for a style
     * @param s Start index
     * @param n Number of characters
     */
    setAllCaps(isAllCaps: boolean, s?: number, n?: number): TextStyle;
    /**
     * Whether small caps is enabled for a style
     */
    isSmallCaps: boolean;
    /**
     * Set the small caps property for a style
     * @param s Start index
     * @param n Number of characters
     */
    setSmallCaps(isSmallCaps: boolean, s?: number, n?: number): TextStyle;
    /**
     * Tracking value for a style
     */
    tracking: number;
    /**
     * Set the tracking style for a style
     * @param s Start index
     * @param n Number of characters
     */
    setTracking(tracking: number, s?: number, n?: number): TextStyle;
    /**
     * The leading value for a style
     */
    leading: number;
    /**
     * Set the leading value for a style
     * @param s Start index
     * @param n Number of characters
     */
    setLeading(leading: number, s?: number, n?: number): TextStyle;
    /**
     * Whether auto leading is enabled for a style
     */
    autoLeading: boolean;
    /**
     * Set the auto leading property for a style
     * @param s Start index
     * @param n Number of characters
     */
    setAutoLeading(autoLeading: boolean, s?: number, n?: number): TextStyle;
    baselineDirection: "default" | "rotated" | "tate-chuu-yoko";
    /**
     *
     * @param s Start index
     * @param n Number of characters
     */
    setBaselineDirection(baselineDirection: "default" | "rotated" | "tate-chuu-yoko", s?: number, n?: number): TextStyle;
    baselineOption: "default" | "subscript" | "superscript";
    /**
     *
     * @param s Start index
     * @param n Number of characters
     */
    setBaselineOption(baselineOption: "default" | "subscript" | "superscript", s?: number, n?: number): TextStyle;
    /**
     * The baseline shift value for a style
     */
    baselineShift: number;
    /**
     * Set the baseline shift value for a style
     * @param baselineShift The baseline shift to set
     * @param s Start index
     * @param n Number of characters
     */
    setBaselineShift(baselineShift: number, s?: number, n?: number): TextStyle;
    /**
     * Whether to apply a fill to the style
     */
    applyFill: boolean;
    /**
     * Enable or disable the fill for a style
     * @param s Start index
     * @param n Number of characters
     */
    setApplyFill(applyFill: boolean, s?: number, n?: number): TextStyle;
    /**
     * The fill color of a style
     */
    fillColor: [number, number, number];
    /**
     * Set the fill color for a style
     * @param fillColor The color to set
     * @param s Start index
     * @param n Number of characters
     */
    setFillColor(fillColor: [number, number, number], s?: number, n?: number): TextStyle;
    /**
     * Whether to apply a stroke to the style
     */
    applyStroke: boolean;
    /**
     * Enable or disable the stroke for a style
     * @param s Start index
     * @param n Number of characters
     */
    setApplyStroke(applyStroke: boolean, s?: number, n?: number): TextStyle;
    /**
     * The stroke colour of a style
     */
    strokeColor: [number, number, number];
    /**
     * Set the stroke colour for a style
     * @param strokeColor The color to set
     * @param s Start index
     * @param n Number of characters
     */
    setStrokeColor(strokeColor: [number, number, number], s?: number, n?: number): TextStyle;
    /**
     * The stroke width for a style
     */
    strokeWidth: number;
    /**
     * Set the stroke width for a style
     * @param strokeWidth The stroke width to set
     * @param s Start index
     * @param n Number of characters
     */
    setStrokeWidth(strokeWidth: number, s?: number, n?: number): TextStyle;
    digitSet: "default" | "hindidigits";
    /**
     * @param s Start index
     * @param n Number of characters
     */
    setDigitSet(digitSet: "default" | "hindidigits", s?: number, n?: number): TextStyle;
    horizontalScaling: number;
    /**
     * @param s Start index
     * @param n Number of characters
     */
    setHorizontalScaling(horizontalScaling: number, s?: number, n?: number): TextStyle;
    verticalScaling: number;
    /**
     * @param s Start index
     * @param n Number of characters
     */
    setVerticalScaling(verticalScaling: number, s?: number, n?: number): TextStyle;
    kerning: number;
    /**
     * @param s Start index
     * @param n Number of characters
     */
    setKerning(kerning: number, s?: number, n?: number): TextStyle;
    kerningType: "metrics" | "optical";
    /**
     * @param s Start index
     * @param n Number of characters
     */
    setKerningType(kerningType: "metrics" | "optical", s?: number, n?: number): TextStyle;
    isLigature: boolean;
    /**
     * @param s Start index
     * @param n Number of characters
     */
    setLigature(ligature: boolean, s?: number, n?: number): TextStyle;
    lineJoin: "bevel" | "miter" | "round";
    /**
     * @param s Start index
     * @param n Number of characters
     */
    setLineJoin(lineJoin: "bevel" | "miter" | "round", s?: number, n?: number): TextStyle;
    /**
     * Replaces the content between `s` and `n` with the given `content`, or if `s` and `n` aren't given replaces the entire string
     * @param s Start index
     * @param n Number of characters
     */
    replaceText(content: string, s?: number, n?: number): TextStyle;
    tsume: number;
    /**
     * @param s Start index
     * @param n Number of characters
     */
    setTsume(tsume: number, s?: number, n?: number): TextStyle;
}
export declare class SourceText extends Property<string> {
    constructor(value: string);
    style: TextStyle;
    /**
     * Get the style object of a text property at a character index
     * @param characterIndex Which character to get the style at
     * @param sampleTime The time to get the style at, defaulting to the current time
     */
    getStyleAt(characterIndex: number, sampleTime?: number): TextStyle;
    /**
     * Used to create a new style object, rather than referencing and modifying an existing one.
     * @returns An empty style object
     */
    createStyle(): TextStyle;
}
export declare class TextPathOptions extends PropertyGroup {
    constructor();
    readonly path: string | undefined;
    readonly reversePath?: boolean;
    readonly perpendicularToPath?: Property<boolean>;
    readonly forceAlignment?: Property<boolean>;
    readonly firstMargin?: Property<number>;
    readonly lastMargin?: Property<number>;
}
export declare class TextMoreOptions extends PropertyGroup {
    constructor();
    readonly anchorPointGrouping: number;
    readonly groupingAlignment: Property<[number, number]>;
    readonly fillAndStroke: number;
    readonly interCharacterBlending: number;
}
export declare class Text extends PropertyGroup {
    constructor();
    readonly sourceText: SourceText;
    readonly pathOption: TextPathOptions;
    readonly moreOption: TextMoreOptions;
}
export declare class MaterialOptions extends PropertyGroup {
    constructor();
    readonly lightTransmission: Property<number>;
    readonly castShadows: Property<boolean>;
    readonly acceptsShadows: Property<boolean>;
    readonly acceptsLights: Property<boolean>;
    readonly ambient: Property<number>;
    readonly diffuse: Property<number>;
    readonly specular: Property<number>;
    readonly shininess: Property<number>;
    readonly metal: Property<number>;
}
export declare class Effects extends PropertyGroup {
}
export declare class Masks extends PropertyGroup {
}
export declare class SourceRect {
    readonly top: number;
    readonly left: number;
    readonly width: number;
    readonly height: number;
}
export declare class Effect {
    /**
     * Returns true if the effect is turned on
     */
    active: boolean;
    /**
     * @returns A property within an effect, e.g. `"Slider"`
     * @param nameOrIndex The name or index of the property to retrieve
     */
    param(nameOrIndex: string | number): Property<any>;
}
export interface Effect {
    /**
     * @returns A property within an effect, e.g. `"Slider"`
     * @param nameOrIndex The name or index of the property to retrieve
     */
    (nameOrIndex: string | number): Property<any>;
}
export declare class Mask {
    /**
     * The opacity value of a mask as a percentage.
     */
    readonly maskOpacity: Property<number>;
    /**
     * The feather value of a mask, in pixels.
     */
    readonly maskFeather: Property<number>;
    /**
     * The expansion value of a mask, in pixels.
     */
    readonly maskExpansion: Property<number>;
    /**
     * True if the mask is inverted or false if it is not.
     */
    readonly invert: Property<boolean>;
}
export declare class Light {
    /**
     * The point of interest values for a light in world space.
     */
    readonly pointOfInterest: Property<Vector3D>;
    /**
     * The intensity values of a light as a percentage.
     */
    readonly intensity: Property<number>;
    /**
     * The color value of a light.
     */
    readonly color: Property<Color>;
    /**
     * The shadow darkness value of a light as a percentage.
     */
    readonly shadowDarkness: Property<number>;
    /**
     * The shadow diffusion value of a light, in pixels.
     */
    readonly shadowDiffusion: Property<number>;
    readonly coneAngle?: Property<number>;
    readonly coneFeather?: Property<number>;
}
export declare class Camera {
    /**
     * The point of interest values of a camera in world space.
     */
    readonly pointOfInterest: Property<Vector3D>;
    /**
     * The zoom values of a camera in pixels
     */
    readonly zoom: Property<number>;
    /**
     * Returns 1 if the Depth Of Field property of a camera is on, or returns 0 if the Depth Of Field property is off.
     */
    readonly depthOfField: Property<number>;
    /**
     * The focus distance value of a camera, in pixels.
     */
    readonly focusDistance: Property<number>;
    /**
     * The aperture value of a camera, in pixels.
     */
    readonly aperture: Property<number>;
    /**
     * The blur level value of a camera as a percentage.
     */
    readonly blurLevel: Property<number>;
    /**
     * True if the camera is the active camera for the composition at the current time: the Video switch for the camera layer is on, the current time is in the range from the In point of the camera layer to the Out point of the camera layer, and it is the first (topmost) such camera layer listed in the Timeline panel. False otherwise.
     */
    readonly active: boolean;
}
export declare class Layer {
    /**
     * The composition time, in seconds, at which the expression is being evaluated.
     */
    readonly time: number;
    /**
     * The project color depth value. For example, colorDepth returns 16 when the project color depth is 16 bits per channel.
     */
    readonly colorDepth: number;
    /**
     * The name of the layer
     */
    readonly name: string;
    /**
     * The source Comp or source Footage object for the layer. Default time is adjusted to the time in the source
     */
    readonly source?: Comp | Footage;
    /**
     * The width of the layer in pixels, same as `source.width`
     */
    readonly width: number;
    /**
     * The height of the layer in pixels, same as `source.height`
     */
    readonly height: number;
    /**
     * The index number of the layer in the composition
     */
    readonly index: number;
    /**
     * The parent Layer object of the layer, if it has one
     */
    readonly parent?: Layer | Light | Camera;
    /**
     * Whether the layer has a parent layer
     */
    readonly hasParent: boolean;
    /**
     * The in point of the layer, in seconds
     */
    readonly inPoint: number;
    /**
     * The out point of the layer in seconds
     */
    readonly outPoint: number;
    /**
     * The start time of the layer in seconds
     */
    readonly startTime: number;
    /**
     * Whether the layer has video data
     */
    readonly hasVideo: boolean;
    /**
     * Whether the layer has audio data
     */
    readonly hasAudio: boolean;
    /**
     * Whether the video switch is enabled, and the current time is between in the `inPoint` and `outPoint` of the layer
     */
    readonly active: boolean;
    /**
     * Whether the video switch for the layer is enabled
     */
    readonly enabled: boolean;
    /**
     * Whether the audio switch is enabled, and the current time is in between the `inPoint` and `outPoint` of the layer
     */
    readonly audioActive?: boolean;
    /**
     *  The value of the Audio Levels property of the layer, in decibels. This value is a 2D value; the first value represents the left audio channel, and the second value represents the right. The value is not the amplitude of the audio track of the source material. Instead, it is the value of the Audio Levels property, which may be affected by keyframes.
     */
    readonly audioLevels?: Property<Vector2D>;
    /**
     * The value of the Time Remap property, in seconds, if Time Remap is enabled.
     */
    readonly timeRemap?: Property<number>;
    /**
     * The marker property group object
     */
    readonly marker?: MarkerProperty;
    /**
     * The transform property group object
     */
    readonly transform: Transform;
    /**
     * The text property group object
     */
    readonly text?: Text;
    /**
     * The material options property group object
     */
    readonly materialOption?: MaterialOptions;
    /**
     * Transforms a given vector from the layer's space to the composition space
     *
     * @param vec The vector to transform
     * @param time The time to sample the vector
     * @returns The vector in the composition space
     */
    toComp<VectorType extends Vector | Vector2D | Vector3D>(vec: VectorType, time?: number): VectorType;
    /**
     * Transforms a given vector from the compositions space to the layer's space
     *
     * @param vec The vector to transform
     * @param time The time to sample the vector
     * @returns The vector in the layer's space
     */
    fromComp<VectorType extends Vector | Vector2D | Vector3D>(vec: VectorType, time?: number): VectorType;
    /**
     * Transforms a given vector from the layers space to the view-independent world space
     *
     * @param vec The vector to transform
     * @param time The time to sample the number
     * @returns The vector in world space
     */
    toWorld<VectorType extends Vector | Vector2D | Vector3D>(vec: VectorType, time?: number): VectorType;
    toCompVec<VectorType extends Vector | Vector2D | Vector3D>(vec: VectorType, time?: number): VectorType;
    fromCompVec<VectorType extends Vector | Vector2D | Vector3D>(vec: VectorType, time?: number): VectorType;
    toWorldVec<VectorType extends Vector | Vector2D | Vector3D>(vec: VectorType, time?: number): VectorType;
    fromWorldVec<VectorType extends Vector | Vector2D | Vector3D>(vec: VectorType, time?: number): VectorType;
    /**
     * Projects a point located in composition space to a point on the surface of the layer (zero z-value) at the location where it appears when viewed from the active camera.
     *
     * @param vec The vector to transform
     * @param time The time to sample the number
     * @returns The vector in on the layers surface space
     */
    fromCompToSurface<VectorType extends Vector | Vector2D | Vector3D>(vec: VectorType, time?: number): VectorType;
    /**
     * Returns the layer's source item at the given time
     * @param time The time at which to get the source
     * @returns The source item
     */
    sourceTime?(time?: number): Footage;
    /**
     * Gets the layer's size and position at a given time
     * @param time The time at which to get the layers bounds
     * @param includeExtents Whether to include areas of the layer outside the bounding box. Applies to Shape Layers and Paragraph Text.
     * @returns An object with properties for layers `top`, `left`, `width` and `height` values at the given time.
     */
    sourceRectAtTime(time?: number, includeExtents?: boolean): SourceRect;
    /**
     * Get the effect on a layer with a given name or index.
     * @param nameOrIndex The effect's name or index
     * @returns The first effect with the given name, or at the given index
     */
    effect(nameOrIndex: number | string): Effect;
    /**
     * Get the mask on a layer with a given name or index.
     * @param nameOrIndex The mask's name or index
     * @returns The first mask with the given name, or at the given index
     */
    mask(nameOrIndex: number | string): Mask;
    /**
     * Sample a layers color at a given point
     * @param point The center point of the sampling area, in layer space
     * @param radius Defines the sample area size, the horizontal and vertical distance from the center
     * @param postEffect Whether to sample the layer after effects and masks are applied
     * @param time The time at which to sample
     * @returns The average color of the layer in the sample area
     */
    sampleImage(point: Vector2D, radius?: Vector2D, postEffect?: boolean, time?: number): Color;
    /**
     * Convert a given value in degrees to radians
     * @param degrees The value to convert
     * @returns The value radians
     */
    degreesToRadians(degrees: number): number;
    /**
     * Convert a given value in radians to degrees
     * @param radians The value to convert
     * @returns The value radians
     */
    radiansToDegrees(radians: number): number;
    /**
     * Gets the footage object for the item with the provided name
     * @param name The file name of the footage item
     * @returns The relevant footage item
     */
    footage(name: string): Footage;
    /**
     * Retrieves a composition by name
     * @param name The name of the composition
     * @returns The composition with the given name
     */
    comp(name: string): Comp;
    /**
     * Converts a given time in seconds to an integer amount of frames
     * @param t The time to convert in seconds
     * @param fps Frames per second to calculate with, defaulting to the compositions frame rate
     * @param isDuration Whether `t` represents a duration rather than an absolute time. Durations are rounded away from zero rather than down.
     * @returns The time in frames
     */
    timeToFrames(t?: number, fps?: number, isDuration?: boolean): number;
    /**
     * Converts a number of frames to time in seconds
     * @param frames The frame count to convert
     * @param fps The frames per second use in the calculation
     * @returns The given frames as time
     */
    framesToTime(frames: number, fps?: number): number;
    /**
     * Converts the given time value to a timecode string (e.g. `"00:00:00:00"`)
     * @param t The time to convert
     * @param timecodeBase The frames per second to use in the calculation
     * @param isDuration Whether `t` represents a duration rather than an absolute time. Durations are rounded away from zero rather than down.
     * @returns The time as a timecode string
     */
    timeToTimecode(t?: number, timecodeBase?: number, isDuration?: boolean): string;
    /**
     * Converts a given time value to a NTSC timecode string
     * @param t The time to convert
     * @param ntscDropFrame
     * @param isDuration Whether `t` represents a duration rather than an absolute time. Durations are rounded away from zero rather than down.
     */
    timeToNTSCTimecode(t?: number, ntscDropFrame?: boolean, isDuration?: boolean): string;
    /**
     * Converts a given time in seconds to a string representing feet of film and frames.
     * @param t The time to convert
     * @param fps Frame rate to use for the conversion
     * @param framesPerFoot Number of frames in one foot of film
     * @param isDuration Whether `t` represents a duration rather than an absolute time. Durations are rounded away from zero rather than down.
     */
    timeToFeetAndFrames(t?: number, fps?: number, framesPerFoot?: number, isDuration?: boolean): string;
    /**
     * Converts a given time in seconds to the current time display format of the Project.
     * @param t The time to convert
     * @param fps Frame rate to use for the conversion
     * @param isDuration Whether `t` represents a duration rather than an absolute time. Durations are rounded away from zero rather than down.
     * @param ntscDropFrame
     */
    timeToCurrentFormat(t?: number, fps?: number, isDuration?: boolean, ntscDropFrame?: boolean): string;
    /**
     * Adds two vectors
     */
    add<A extends NumericValue, B extends NumericValue>(a: A, b: B): MathReturn<A, B>;
    /**
     * Subtracts two vectors
     */
    sub<A extends NumericValue, B extends NumericValue>(a: A, b: B): MathReturn<A, B>;
    /**
     * Multiplies a vector by a given scalar amount
     * @param vec1 The vector to multiply
     * @param amount The amount to multiply by
     */
    mul<VectorType extends NumericValue>(vec1: VectorType, amount: number): VectorType;
    /**
     * Divides a vector by a given scalar amount
     * @param vec1 The vector to divide
     * @param amount The amount to divide by
     */
    div<VectorType extends NumericValue>(vec1: VectorType, amount: number): VectorType;
    /**
     * Constrains a given number, or each element of an array, to fall within a a given range
     * @param value Array or number to constrain
     * @param limit1 Lower limit
     * @param limit2 Upper limit
     */
    clamp<T extends NumericValue>(value: T, limit1: number, limit2: number): T;
    /**
     * @returns the dot (inner) product of two vectors
     */
    dot(vec1: Vector, vec2: Vector): Vector;
    /**
     * @returns the cross product of two vectors
     */
    cross(vec1: Vector, vec2: Vector): Vector;
    /**
     * @returns The given vector normalized so it has a length of 1
     */
    normalize(vec1: Vector): Vector;
    /**
     * @returns The length of a given vector, or if two vectors are provided the distance between them
     */
    length(point1: Vector, point2?: Vector): number;
    /**
     * Used to orient a layer towards a given point in 3D space
     * @param fromPoint The location in world space of the layer you want to orient
     * @param atPoint The point in world space you want to point the layer at
     * @returns An orientation value that can be used to orient the layer so that the z-axis points at the `atPoint`
     */
    lookAt(fromPoint: Vector, atPoint: Vector): Vector3D;
    /**
     * Used to modify the random seed for an expression
     * @param offset A value used to modify the random seed
     * @param timeless Whether the random seed should be consistent across time
     */
    seedRandom(offset: number, timeless?: boolean): void;
    /**
     * @returns a random value either between `0` and `1`, `0` and the first argument, or the first and second argument if two are provided. If the arguments are arrays, an equal length array of random values will be returned
     * @param minValOrArray If only one argument is provided, the max value for the random number, otherwise the minimum value
     * @param maxValOrArray The maximum value to return
     */
    random(minValOrArray?: number | [], maxValOrArray?: number | []): number | [];
    /**
     * @returns a random value with a gaussian distribution either between `0` and `1`, `0` and the first argument, or the first and second argument if two are provided. If the arguments are arrays, an equal length array of random values will be returned
     * @param minValOrArray If only one argument is provided, the max value for the random number, otherwise the minimum value
     * @param maxValOrArray The maximum value to return
     */
    gaussRandom(minValOrArray?: number | [], maxValOrArray?: number | []): number | [];
    /**
     * Used to get a random value via Perlin noise, where inputs values that are close together will result in output values that are closer together.
     * @param valOrArray The noise input value
     * @returns A value between `-1` and `1`
     */
    noise(valOrArray: number | []): number;
    /**
     * @returns A given value, mapped from one range to another, clamped to the output range. If only 3 parameters are given, the input range is `0` to `1` and the given values are used for the output range.
     * @param t The input value to be re-mapped
     * @param tMin The inputs low floor
     * @param tMax The inputs high ceiling
     * @param value1 The output floor
     * @param value2 The output ceiling
     */
    linear(t: number, tMin: number, tMax: number, value1?: number | [], value2?: number | []): number | [];
    /**
     * @returns A given value, mapped from one range to another, clamped to the output range. The mapping will ease in and out so it reaches the output range with a velocity of `0`. If only 3 parameters are given, the input range is `0` to `1` and the given values are used for the output range.
     * @param t The input value to be re-mapped
     * @param tMin The inputs low floor
     * @param tMax The inputs high ceiling
     * @param value1 The output floor
     * @param value2 The output ceiling
     */
    ease(t: number, tMin: number, tMax: number, value1?: number | [], value2?: number | []): number | [];
    /**
     * @returns A given value, mapped from one range to another, clamped to the output range. The mapping will ease out with a velocity of `0`. If only 3 parameters are given, the input range is `0` to `1` and the given values are used for the output range.
     * @param t The input value to be re-mapped
     * @param tMin The inputs low floor
     * @param tMax The inputs high ceiling
     * @param value1 The output floor
     * @param value2 The output ceiling
     */
    easeIn(t: number, tMin: number, tMax: number, value1?: number | [], value2?: number | []): number | [];
    /**
     * @returns A given value, mapped from one range to another, clamped to the output range. The mapping will ease into the output range  with a velocity of `0`. If only 3 parameters are given, the input range is `0` to `1` and the given values are used for the output range.
     * @param t The input value to be re-mapped
     * @param tMin The inputs low floor
     * @param tMax The inputs high ceiling
     * @param value1 The output floor
     * @param value2 The output ceiling
     */
    easeOut(t: number, tMin: number, tMax: number, value1?: number | [], value2?: number | []): number | [];
    /**
     * Converts a color in RGBA space to HSLA
     * @param rgbaArray Input RGBA array of values between 0 and 1
     * @returns An array of hue, saturation, lightness and alpha values between 0 and 1
     */
    rgbToHsl(rgbaArray: Color): Color;
    /**
     * Converts a color in HSLA space to RGBA
     * @param rgbaArray Input HSLA array of values between 0 and 1
     * @returns An array of red, green, blue and alpha values between 0 and 1
     */
    hslToRgb(hslaArray: Color): Color;
    /**
     * Converts a color in hex triplet space to RGB, or in hex quartet space to RGBA space. For hex triplets, alpha defaults to 1.0
     * @param hex String representing an hex triplet (6 digits, no alpha channel) or quartet (8 digits, includes alpha channel) containing only numerals or characters A–F. Optional leading characters 0x, 0X, or # are ignored. Characters beyond 8 digits are ignored.
     */
    hexToRgb(hex: string): Color;
}
export declare class Footage {
    /**
     * The name of the footage item as shown in the project panel
     */
    readonly name: string;
    /**
     * The width of the footage item, in pixels
     */
    readonly width?: number;
    /**
     * The height of the footage item, in pixels
     */
    readonly height?: number;
    /**
     * The duration of the footage item, in seconds
     */
    readonly duration?: number;
    /**
     * The duration of a frame in the footage item, in seconds
     */
    readonly frameDuration?: number;
    /**
     * Whether the timecode is in NTSC drop-frame format
     */
    readonly ntscDropFrame?: boolean;
    /**
     * The pixel aspect ratio of the footage
     */
    readonly pixelAspect?: number;
    /**
     * The contents of a JSON file as a string
     */
    readonly sourceText?: string;
    /**
     * The data of a JSON file as an array of `sourceData` objects
     */
    readonly sourceData?: SourceData[];
    /**
     * @returns The value of specified static or dynamic data stream in a .mgJSON file
     * @param dataPath the path in the hierarchy to the desired data stream
     */
    dataValue?(dataPath: []): number;
    /**
     * @returns The number of samples in a specified dynamic data stream in a .mgJSON file
     * @param dataPath the path in the hierarchy to the desired dynamic data stream
     */
    dataKeyCount?(dataPath: []): number;
    /**
     * @returns The time in seconds for the samples of a specified dynamic data stream in a .mgJSON file
     * @param dataPath The path in the hierarchy to a dynamic data stream.
     * @param t0 The start time, in seconds, of the span from which to return samples. Defaults to startTime.
     * @param t1 The end time, in seconds, of the span from which to return samples. Defaults to endTime.
     */
    dataKeyTimes?(dataPath: [], t0?: number, t1?: number): number[];
    /**
     * @returns The values for the samples of a specified dynamic data stream in a .mgJSON file.
     * @param dataPath The path in the hierarchy to a dynamic data stream.
     * @param t0 The start time, in seconds, of the span from which to return samples. Defaults to startTime.
     * @param t1 The end time, in seconds, of the span from which to return samples. Defaults to endTime.
     */
    dataKeyValues?(dataPath: [], t0?: number, t1?: number): number[];
}
export {};
