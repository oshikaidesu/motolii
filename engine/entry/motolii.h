#ifndef MOTOLII_ENTRY_MOTOLII_H_
#define MOTOLII_ENTRY_MOTOLII_H_
/* motolii.h: the engine's C API. It declares every call the app (Flutter,
   through dart:ffi) makes on the engine, and nothing else. The app holds no
   project. It holds a Motolii handle and layer numbers. Each call is one change
   and one undo step, and is stored in the project's file by the time the call
   returns. A call that is not done returns 0, changes nothing, and sets a
   message that motolii_error returns.

   Layer kinds: video; image (an After Effects file, a .jpg, or a .png); text (a
   font, .ttf); solid (.glb, .gltf, or one of ring, gem, cube). A solid's fill
   is what it is made of: a color, or glass.

   The names of a layer's properties are ThorVG's own where ThorVG has one (x,
   y, rotate, size, blend, text, fill, begin). document/kinds.h lists them. */
#ifdef __cplusplus
extern "C" {
#endif
typedef struct Motolii Motolii;

/* Sets the folder that holds the engine's own files, such as its materials.
   Call it once, before a project is opened. */
void motolii_home(const char* folder);
/* Opens a project on a preview. Returns NULL if the file is not a project. A
   project that stores its own size is opened at that size; a new project is
   created `wide` by `high` points. motolii_size_of returns the size of the
   preview the project is open on. motolii_fits returns 1 if the preview is the
   size the project specifies now, and 0 if the project's size has changed,
   including by undo or redo, in which case the caller must close the project
   and open it again. */
Motolii* motolii_open(const char* document, int wide, int high);
int motolii_size_of(Motolii* m, int* wide, int* high);
int motolii_fits(Motolii* m);
/* The work area is the span that loops in playback and is exported as video.
   When it is not set it is the whole project. Changing it is one undo step.
   Marks are named times: motolii_later's "mark" adds one, and an empty name
   removes the one at that time. motolii_marks returns one line per mark in time
   order, "time name", valid until the next call. */
/* Turns looping over the work area on (1, the state when a project is opened)
   or off (0, playback stops at the end). A value below 0 only asks. */
int motolii_loop(Motolii* m, int on);
/* Gets the start and end of the work area, in seconds. */
int motolii_work_of(Motolii* m, double* from, double* to);
/* Sound of a video layer. motolii_loudness writes the loudness in dB (0 is full
   scale) of the layer's sound, 100 samples per second of the video's own time,
   at most `room` of them. It returns how many samples there are, or 0 if the
   layer has no sound or is not a video. motolii_strikes finds the times where
   the sound grows louder by at least `rise` dB within 30 ms. It writes at most
   `room` of them to `at` and returns how many there are. If `own` is nonzero
   the times are in the video's own seconds, otherwise they are project times
   where the video shows them. A file's sound is analyzed once, as fast as it
   decodes. */
int motolii_loudness(Motolii* m, int layer, float* db, int room);
int motolii_strikes(Motolii* m, int layer, double rise, int own, double* at,
                    int room);
/* Writes the loudness in dB at n times of the project, from `from` up to but
   not including `to`, where the video shows them. A sample is -100 where the
   sound is silent or not shown. Returns n, -1 if the sound has not been read
   yet, or 0 if there is no sound. */
int motolii_loudness_over(Motolii* m, int layer, double from, double to, int n,
                          float* db);
const char* motolii_marks(Motolii* m);
/* Returns one line per mark that has a label color, in time order: "time
   color", with the color from 1 to 16. */
const char* motolii_mark_colours(Motolii* m);
/* Returns the app's choices that are stored with the project and are not undo
   steps, one per line, "name word". They are set with motolii_later's
   "setting". */
const char* motolii_settings(Motolii* m);
/* Ranks shelf items against the words the user typed. `items` holds one item
   per line, "id<TAB>its name and label<TAB>what it does". Returns the best
   `limit` matches (5 when limit is 0), nearest first, one per line,
   "id<TAB>score", with the score from 0 to 100. Uses RapidFuzz (MIT), which
   tolerates typos, partial words and abbreviations. */
const char* motolii_find(Motolii* m, const char* query, const char* items,
                         int limit);
/* Guides are lines across the image: an x guide is vertical and a y guide is
   horizontal, placed at a distance in points from the image's left or top edge.
   Changing one is an undo step (motolii_later's "guide"). motolii_guides
   returns one line per guide, such as "x 150", valid until the next call. */
const char* motolii_guides(Motolii* m);
/* Closes the project and frees the handle. */
void motolii_close(Motolii* m);
/* Evaluates an arithmetic expression typed in a number field (+ - * / and
   parentheses), as After Effects, Figma and Blender do. SQLite evaluates it, as
   it does easings. Writes the result to *is and returns 1, or returns 0 if the
   text is not an expression. */
int motolii_work_out(Motolii* m, const char* sum, double* is);
/* Returns the reason the last call that was not done was not done. */
const char* motolii_error(Motolii* m);

/* Returns the kind of layer a file makes, or "" if it makes none. */
const char* motolii_kind_of(const char* file);
/* Returns 1 if a text in that font file can be those words. Any thread, while a
 * project is open. */
int motolii_sets(const char* font, const char* words);
/* Returns the letters of those words that the font file does not have, each
   once, or "" if it has them all. If there are any, a tab and the name of the
   font that draws them all instead follow; that part is "" if no font has them
   all. Any thread. Valid until the next call. */
const char* motolii_font_lacks(const char* font, const char* words);
/* Draws those words in that font file as white on black into grey, w * h bytes,
   as large as they fit and no larger than font size `most` when most is above
   0. Any thread, while a project is open. Returns 0 if the words could not be
   drawn. */
int motolii_type_frame(const char* font, const char* words, int w, int h,
                       float most, unsigned char* grey);
/* Lays out n points of dims numbers each on a plane so that similar points lie
   near each other (t-SNE). Writes 2n numbers to xy, with x and y each from 0
   to 1. Any thread. Returns 0 if there are fewer than 4 points. */
int motolii_map(const float* points, int n, int dims, double* xy);
/* Assigns each of n places (x and y from 0 to 1) its own cell of a cols x rows
   grid, so that the places are as near their cells as they can be all together.
   cell[i] receives row * cols + column. Any thread. Returns 0 if the places
   could not be laid out. */
int motolii_grid(const double* xy, int n, int cols, int rows, int* cell);
/* Describes each of n images (224 x 224 pixels, RGBA) as a vector of dims
   numbers scaled to length 1, using a CLIP image encoder stored as an ONNX
   file. Any thread. Returns 0 on failure. */
int motolii_likeness(const char* model, const unsigned char* rgba, int n,
                     int dims, float* out);
/* Writes a thumbnail .png of the video, `wide` pixels wide, taken `fraction` (0
   to 1) of the way through it. */
int motolii_thumbnail_at(const char* video, const char* png, int wide,
                         double fraction);
/* Writes a thumbnail .png of the video, `wide` pixels wide, taken `seconds`
 * into it. */
int motolii_thumbnail_seconds(const char* video, const char* png, int wide,
                              double seconds);
/* Returns what a media file is, as GStreamer's discoverer reports it: "width
   height rate seconds format", or "" if the file cannot be read. Valid until
   the next call on this thread. */
const char* motolii_media_info(const char* file);
/* Checks a video for flashes and patterns that may cause seizures, using EA's
   IRIS (media/video_flash_check.h). Returns the path of the result.json it
   wrote under `folder`, with frameData.json beside it, or "" if the video could
   not be read. Any thread, one at a time. Valid until the next call on this
   thread.
 */
const char* motolii_flashes(const char* video, const char* folder);
/* Returns a font file's kinds as CoreText reads them: serif sans script mono
   bold light italic symbols ornaments, and the languages beyond Latin that it
   supports (japanese korean chinese russian greek arabic hebrew thai hindi). */
const char* motolii_font_tags(const char* path);
/* Adds a layer of the given kind (kind "" means whatever the file makes),
   starting at the preview's current time. Returns its number, or 0 if no layer
   was made. */
int motolii_add(Motolii* m, const char* kind, const char* file);
/* Removes a layer. */
int motolii_remove(Motolii* m, int layer);
/* Sets a property to a constant number. */
int motolii_set(Motolii* m, int layer, const char* name, double number);
/* Sets a property to a word. */
int motolii_say(Motolii* m, int layer, const char* name, const char* word);
/* Sets a keyframe of a property at a time. */
int motolii_key(Motolii* m, int layer, const char* name, double at,
                double number);
/* Creates keyframes of a property from the notes of a MIDI file, held (not
   interpolated), as om_midi does. `kind` selects what each note keys: velocity
   (0 to 1), pitch, count, on (1 or 0), or bool. channel -1 means any channel.
   bpm is the tempo the file's beats are played at, and 0 means the file's own
   tempo. */
int motolii_midi(Motolii* m, int layer, const char* name, const char* file,
                 const char* kind, int channel, double bpm);
/* The span from one keyframe to the next has an easing, which defines how the
   value moves across it. An easing is a name with up to four numbers, such as
   "smooth", "hold" or "wiggle 3 0.2". A custom easing is an SQLite expression
   in u (progress through the span, 0 to 1), t (seconds into it), d (its
   length), a and b (the values of the two keyframes) and p1 to p4 (the numbers
   given with it). It is accepted only if it equals a at the start and b at the
   end. motolii_easing sets the easing of the span that starts at the keyframe
   at time `at`. */
int motolii_easing(Motolii* m, int layer, const char* name, double at,
                   const char* easing);
/* Returns the effects a layer may be given, one per line, "name\tvalue\tlabel",
   where label says what the effect is for (the shelf's kind). Valid until the
   next call. */
const char* motolii_effect_names(Motolii* m);
/* Puts an effect on a layer at a time, or takes it off, with its keyframes, if
   it is already on. This is one undo step. The effect's card is shown while it
   is on (motolii_cards). */
int motolii_effect(Motolii* m, int layer, const char* name, double at);
/* Returns the easing of the span that begins at the keyframe at that time, as
   text, or "" if there is no keyframe there. Valid until the next call. */
const char* motolii_easing_of(Motolii* m, int layer, const char* name,
                              double at);
/* Returns every span between keyframes of a layer's keyed properties, one per
   line, "from\tto\teasing". Valid until the next call. */
const char* motolii_layer_stretches(Motolii* m, int layer);
/* Returns the easings the project knows. Valid until the next call. */
const char* motolii_easings(Motolii* m);
/* Returns the names alone, separated by spaces: the nine built-in kinds, then
   the easings defined in the project. Valid until the next call. */
const char* motolii_easing_names(Motolii* m);
/* Returns the numbers of a kind as the app takes them: a name, lowest and
   highest for each, such as "seed 1 999 grain 0 0.5 ...". Returns "" for a kind
   with no numbers and for an easing defined in the project. */
const char* motolii_easing_numbers(Motolii* m, const char* kind);
/* Evaluates an easing, either one of the nine built-in kinds or one defined in
   the project, at progress u through the span. Returns how far the value has
   gone, 0 at the beginning and 1 at the end. */
double motolii_easing_at(Motolii* m, const char* easing, double u);
/* Reads a property as the preview shows it at a time, and writes it to *is.
   Returns 2 if the value is driven (by a relation or a behavior), 1 if it is
   the property's own, and 0 if the property has none. */
int motolii_shows(Motolii* m, int layer, const char* name, double at,
                  double* is);
/* What the app reads to draw its lists. motolii_layers writes the numbers of
   the layers into `layers`, as many as fit in `room`, and returns how many
   layers there are. motolii_word returns a layer's word property by name (kind,
   file, shape, blend, text, fill), or "" if it has none. With the name "name"
   it returns what the layer is called in lists: a text layer's text, a shape
   layer's shape, or a file layer's file name. It is valid until the next call.
   motolii_lasts returns how long a layer is on, in seconds, or a value below 0
   if it is on for good. motolii_key_times writes the times of the keyframes of
   a property, and none if the property has none. */
int motolii_layers(Motolii* m, int* layers, int room);
const char* motolii_word(Motolii* m, int layer, const char* name);
double motolii_lasts(Motolii* m, int layer);
int motolii_key_times(Motolii* m, int layer, const char* name, double* at,
                      int room);
/* Writes every keyframe time of any of a layer's properties, each once and in
   time order, at most `room` of them. Returns how many there are. */
int motolii_layer_key_times(Motolii* m, int layer, double* at, int room);
/* Samples how a layer moves over time, with the placement of its copy: the
   layer's script, its expressions and its keyframes are all included. There are
   n samples at evenly spaced times from `from` up to but not including `to`.
   Sample i is path[4i..4i+3]: x and y (units of the preview), how far the layer
   is turned (degrees) and how large it is (a share of its own size). This is
   for the app's small preview that plays by itself. Returns 0 if there is no
   such layer. */
int motolii_path(Motolii* m, int layer, int copy, double from, double to, int n,
                 double* path);
/* The same as motolii_path in 3D: x, y and z (units of the preview), then how
 * large. */
int motolii_path3(Motolii* m, int layer, int copy, double from, double to,
                  int n, double* path);
/* Dragging a layer. drag_start, drag_update and drag_end, like Flutter's
   GestureDetector onPanStart, onPanUpdate and onPanEnd, are the one way to drag
   anything with a pointer. What is dragged shows at once but is not part of the
   project until drag_end, which makes it one undo step. With keep 0 nothing
   happens. The engine does the arithmetic: the app only says where the pointer
   is, never what the project is to hold. `by` selects what drag_update drags:
     "place"             the layer on the preview: a and b are how far the
   pointer has gone since drag_start, in points of the image (right, down). The
   layer stays under the pointer at its own depth. "bar"               the
   layer's bar on the timeline: a is how many seconds later it comes on. "head",
   "tail"      the layer's bar cut at one end: a is how many seconds later that
   end is. A video cut at its head goes on showing at each time what it showed
   there. a property's name   that number dragged: a is what it is now.
   motolii_drag_start on the layer that is already being dragged continues the
   same drag. */
int motolii_drag_start(Motolii* m, int layer);
int motolii_drag_update(Motolii* m, const char* by, double a, double b);
/* Returns how many points of the image make one unit of the preview, at z 0. */
double motolii_point(Motolii* m);
/* Returns how the app reads a property: "times from", where the shown value is
   the stored value times `times`, plus `from`. */
const char* motolii_reading(Motolii* m, int layer, const char* name);
/* What the user does to a property at a time is stored by the project's own
   rules: the property is changed there (see motolii_keying for what that means
   for a property with keyframes and one without). motolii_moving returns the
   names of a layer's properties that take keyframes, separated by spaces. Valid
   until the next call. */
/* With `on` set, every property the user changes or drags gets a keyframe at
   that time. If its first keyframe is later than the time at which this was
   turned on, the value it had is also stored as a keyframe there, so that it
   travels from there. With `on` clear, the state when a project is opened, a
   property with keyframes gets a keyframe where it is changed, and one without
   just takes the new value. A value of `on` below 0 only asks. Returns whether
   keying is on now. */
int motolii_keying(Motolii* m, int on);
const char* motolii_moving(Motolii* m, int layer);
/* motolii_values returns the names of all of a layer's properties, separated by
   spaces, valid until the next call. motolii_range gets the lowest and highest
   value of a number property, and returns 0 if it has no such range. */
const char* motolii_values(Motolii* m, int layer);
int motolii_range(Motolii* m, int layer, const char* name, double* low,
                  double* high);
/* Returns the cards on which the user sees a layer's properties, besides where
   it is and its fill: "title: name name; title: name". Valid until the next
   call. A property added to the project's cards is shown by an app that reads
   this, with no code of its own. */
const char* motolii_cards(Motolii* m, int layer);
/* Returns the cards the layer may be given but is not shown, which the user can
   ask for, in the same format as motolii_cards. */
const char* motolii_cards_more(Motolii* m, int layer);
/* Returns how a property is shown to the user: "look\tunit\tplain
   name\tlow\thigh\tfold", or empty if it is shown as its range says. Valid
   until the next call. The look is one of: count, onoff, angle, stage (a length
   in the preview, shown in points of the image), down (a distance up the
   preview, shown downward), share (0 to 1, shown in hundredths), colour,
   colours, numbers, layer, seed or none. low and high are the span the control
   covers, in the project's own units. fold is the name of the fold the property
   lies in on its card, or empty if it is not folded. */
const char* motolii_shown(Motolii* m, const char* name);
/* Returns the create scripts, one per line, "name\twhat it makes". A closed
   pack gives "name\twhat\tprogram\tpath": what it was written for and its
   file. Valid until the next call. */
const char* motolii_create_scripts(Motolii* m);
/* Returns the shelf's presets, one per line, "name\tpath\tlabel\timage". A
   preset is a layer's properties, effects and keyframes, except what kind of
   layer it is, its hold and where it lies, stored as a file of its own. Valid
   until the next call. */
const char* motolii_presets(Motolii* m);
/* Runs a create script at the preview's current time, as one undo step. Returns
   the new layer, or 0 if none was made. */
int motolii_create(Motolii* m, const char* script);
/* Returns the full-frame effects on the shelf, one per line:
   "name\tpath\tlabel\timage\thome\tsame\tabout\ttags". tags are what is read
   from the effect's file (isf.h, isf_tags). label is what the file's "//
   --label:" line says. image is the effect's tile, "" if there is none yet.
   home is where a tile drawn for the effect goes. same is "same" when the
   effect is seen to change nothing (document/scripts/recipes.h, doc_tile).
   Valid until the next call. The preview's script is the paths of the effects
   on it, separated by spaces, with the first nearest the image. AviUtl2's
   scripts follow (aviutl_scripts/, to any depth; for an @ file, each
   "file#name"), each for a layer's fx. */
const char* motolii_effects(Motolii* m);
/* Tells the engine that a file or folder the shelves read from was written,
   added or removed. The app's own file watch reports this, or the user asks for
   it. The shelves, effects, scripts and create scripts read their files again
   at their next use, and not before. */
void motolii_files_changed(void);
/* Returns the motions a layer may be given (Cavalry's Animators), one per line,
   "name\tpath\tlabel". Valid until the next call. A layer's script is the path
   of the one it has. A text layer that is given one moves letter by letter. */
const char* motolii_animators(Motolii* m);
/* Returns the relations written as files (a .js file each in relations/), one
   per line, "name\tfile", like motolii_animators. */
const char* motolii_relations(Motolii* m);
/* Returns a line of words saying what the render thread has spent its time on
   since the engine was opened, for measuring. */
const char* motolii_spent(Motolii* m);
/* Returns what the project's undo steps changed since the last call, one per
   line: "layers" when a layer was added or removed, then "layer name" for each
   changed property. Asking forgets them. It also returns the names of the
   properties that change which cards a layer has. */
const char* motolii_shaping(Motolii* m);
/* Queues a change without waiting for the render thread. It is queued in order
   behind all others, and a ticket is returned at once. `call` is one of the
   following, with its other arguments. set, say, drag_start, undo, redo   as
   the calls of the same names drag_update   name is `by` and number is a, as in
   motolii_drag_update. Or name is "effect" and word is an effect file, which is
   shown on the dragged layer, is not part of the project until drag_end, and is
   not put on then. drag_end      number is keep. together      number is 1 to
   begin and 0 to end. duck          keys a video's volume down by 12 dB while
   another video is louder than -30 dB, as Audacity's Auto Duck does. relate
   puts the layers listed in word (numbers) into the relation `layer`, as they
                   show now.
     free          takes `layer` out of the relation `number`, as if its
   strength were 0 for good: it goes back to the relation under it, or to its
   own value. lead          the relation `layer` is led by the layer `number`,
   and nothing moves. release       lets go of the relation `layer`, and each of
   its layers stays where it shows now. key           a keyframe of `name` at
   the time in word, holding number. A layer of -1 means the layer the last add
   made. set with word "last_added" sets a property that names a layer to that
   layer, and number is that layer. motolii_answer returns -1 if the call is not
   done yet, 0 if it was refused (motolii_answer_why says why, until the next
   answer), and 1 if it is done. An answer is returned once. */
int motolii_later(Motolii* m, const char* call, int layer, const char* name,
                  const char* word, double number);
int motolii_answer(Motolii* m, int ticket);
const char* motolii_answer_why(Motolii* m);
/* Returns the words a property of a layer may be, separated by spaces, or "" if
   any word is allowed or the property is not a word. Valid until the next call.
 */
const char* motolii_words(Motolii* m, int layer, const char* name);
/* Groups several calls into one act, such as changing a property and putting
   its keyframe. The changes made from motolii_together(m, 1) to
   motolii_together(m, 0) are one undo step, and if one of them is refused none
   of them is made and 0 comes back. Acts may be nested, and the outermost is
   the undo step. */
int motolii_together(Motolii* m, int on);
/* Undoes the last undo step. */
int motolii_undo(Motolii* m);

/* Returns how long the project runs, in seconds. */
double motolii_seconds(Motolii* m);
/* Sets the preview's time. It is sent, not waited for, and a later call
   replaces it. The snapshot tells what was drawn and at what time. */
int motolii_at(Motolii* m, double seconds);
/* Copies the project, as name.motolii, and the files its layers use into a
   folder, and rewrites the file names in the copy to the copied files. Returns
   how many files were copied, or -1 on failure. */
int motolii_pack(Motolii* m, const char* folder, const char* name);
/* Writes the project's poster image (at its poster_at time, else now), 256
   pixels on its longer side, to png and stores it in the project with the
   project's size and length. */
int motolii_poster(Motolii* m, const char* png);
/* Reads a project without opening it: "width height seconds rate" as last
   stored, with its poster image written to png (null: not written), or "" if
   none was stored. Any thread. */
const char* motolii_doc_properties(const char* path, const char* png);
/* Writes the preview as it is now to a .png file. */
int motolii_still(Motolii* m, const char* png);
/* Writes the whole project as a video (.mp4 H.264, .mov HEVC, .gif, or .png
   with one image per frame; see render_draw.h), with the sound of its videos.
   Other calls are answered meanwhile from another thread, but the project is
   not changed, and nothing is held until it is done. */
int motolii_export(Motolii* m, const char* mp4);
/* Returns the frame rate of the exported video, in frames per second. An app
   that counts in frames counts in these. */
int motolii_rate(Motolii* m);
/* Returns a snapshot of the project for the app (docs/app/BRIDGE.md), read
   without the project lock. which 1 is the project's snapshot: its own part,
   and the part of each layer newer than `since`. which 2 is the time snapshot.
   The result is JSON in a copy that the caller frees with free(). *version is
   set to the version the snapshot is as of. */
char* motolii_snapshot(Motolii* m, int which, long since, long* version);
/* Sets the app's one listener. It is called from the render thread when new
   snapshots exist, with a bit mask: 1 the project's snapshot, 2 the time
   snapshot, 4 the cached frames (motolii_cache), 8 an answer to a change queued
   with motolii_later (motolii_answer). */
void motolii_add_listener(Motolii* m, void (*listener)(int which));
/* While on, the app's main thread must not wait on the render thread. A change
   it waits for, or a read that waits on the project for more than 2 ms, is
   recorded. Watching is on from the time the project is opened. */
void motolii_watch(Motolii* m, int on);
/* Returns what was recorded since motolii_watch(1), one per line, each starting
   with its clock time (hh:mm:ss.mmm), then its name and duration, or "" if
   nothing was recorded. */
const char* motolii_broken(Motolii* m);
/* Returns how many times the app's thread waited, or the engine took over 1/60
   s to draw a frame, by its own clock or the GPU's, since watching began. Reads
   without waiting. */
long motolii_broken_count(Motolii* m);
/* Returns every keyframe of the project, one per line. Valid until the next
 * call. */
const char* motolii_list(Motolii* m);
/* The preview's frame as it is drawn, for the app to show without copying it.
   The engine keeps its own clock: it draws when something has changed or time
   is going on, and the app only asks for the last finished frame. motolii_front
   returns a CVPixelBufferRef on macOS, held for the caller, who must release
   it. It and motolii_frames, how many frames have been finished, may be called
   from any thread. */
void* motolii_front(Motolii* m);
/* The desk is the app's whole preview pane, w x h pixels. While it is on, the
   frame is drawn there instead of on the preview's own buffer, which
   motolii_front keeps at its last frame. The preview lies with its top left at
   x, y, `scale` pixels to a point of it, and what lies off the preview is seen
   around it, with the picked layer marked over it. `point` is the pixels to a
   point of the screen in which the marks are sized. A w of 0 turns it off. It
   is made again when its size changes. */
void* motolii_desk_front(Motolii* m);
unsigned long long motolii_desk_frames(Motolii* m);
unsigned long long motolii_frames(Motolii* m);
/* Sets a callback that is called on the render thread whenever a frame, the
   preview's or the desk's, is finished: listener(with). motolii_front or
   motolii_desk_front then returns it, as with Thermion's
   markTextureFrameAvailable, so the app does not poll on a clock of its own. */
void motolii_finished(Motolii* m, void (*listener)(void*), void* with);
/* Returns the preview's frames that are cached on disk for playback
   (preview/playback_cache.h), as spans of frames at motolii_rate, "from to from
   to", or "" if there are none. How many times that has changed is read without
   waiting, as motolii_revision does. */
const char* motolii_cache(Motolii* m);
/* Returns the titles of a layer's effect cards in the order its effects are
   laid, separated by
   ";", or "" if there are none. Move one with motolii_later "fx_move" (word: a
   title, number: how many places, up when less than 0). */
const char* motolii_fx_titles(Motolii* m, int layer);
/* Starts playback (playing nonzero), in which time goes on by the clock and
   goes round again at the end, or stops it. */
int motolii_play(Motolii* m, int playing);
/* Returns the preview's current time. */
double motolii_now(Motolii* m);
#ifdef __cplusplus
}
#endif
#endif  // MOTOLII_ENTRY_MOTOLII_H_
