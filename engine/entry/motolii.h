/* motolii.h: the editing inside, as C calls: all that a shell on a screen (Flutter, by dart:ffi) calls, and nothing
   else. The shell holds no document: it holds this handle and the numbers of layers. One call = one change = one step
   of undo, in the document's file as the call returns. A call that is not done returns 0, changes nothing, and
   motolii_error() says why.
   kinds: video, image (an After Effects file, a .jpg, a .png), text (a font, .ttf), solid (.glb, .gltf, or one of ring, gem, cube)
   A solid's fill is what it is made of: a colour, or glass. The names of a layer's values are ThorVG's own where it has one (x, y, rotate, size, blend,
   text, fill, begin): doc.h lists them. */
#ifndef MOTOLII_H
#define MOTOLII_H
#ifdef __cplusplus
extern "C" {
#endif
typedef struct Motolii Motolii;

void motolii_home(const char* folder);                             /* where the inside's own files are (its materials, its room): said once, before a document is opened */
/* The document on a stage (0: not a document). A document says its own size: one that is there is opened at it; a
   new one is made `wide` by `high` points. motolii_size_of: the size of the stage it is open on. motolii_fits: 1 if
   the stage is the size the document says now; 0 (after the document says another size, or an undo or redo of one):
   close it and open it again. */
Motolii* motolii_open(const char* document, int wide, int high);
int motolii_size_of(Motolii* m, int* wide, int* high);
int motolii_fits(Motolii* m);
/* The work area: the stretch played round and written as a video (not said: all of it); a change is a step. The marks:
   moments with a name (motolii_later's "mark"; with "" the one there is taken away); motolii_marks: a line each, in time, "moment name"
   (until the next call). */
int motolii_loop(Motolii* m, int on);   /* play goes round the work area (1, as a document is opened) or stops at its end (0); below 0: only asks */
int motolii_work_of(Motolii* m, double* from, double* to);
/* A video's sound: its loudness (dB, 0 at full) 100 times a second of its own, as many as there are (room: how many db
   holds; 0: no sound, or not a video); and the moments of the document where it strikes (grows `rise` dB louder within
   30 ms), as many as there are, where its video shows them. Read once a file, as fast as it decodes. */
int motolii_loudness(Motolii* m, int layer, float* db, int room);
int motolii_strikes(Motolii* m, int layer, double rise, int own, double* at, int room);
int motolii_loudness_over(Motolii* m, int layer, double from, double to, int n, float* db);   /* loudness at n moments of the document, where the video shows them (-100: silent or not shown); -1: not read yet, 0: no sound */   /* own: in the video's own seconds instead */
const char* motolii_marks(Motolii* m);
const char* motolii_mark_colours(Motolii* m);   /* a line each, in time, "moment colour" (1 to 16, the label colours): the marks that have one */
const char* motolii_settings(Motolii* m);   /* the window's choices kept with the document, not steps (asked later: setting): a line each, "name word" */
/* The words a hand types against a shelf's items (`items`: "id<TAB>its name and label<TAB>what it does" a line), nearest
   first, the best `limit` (5 when 0): "id<TAB>score" a line, the score 0 to 100. RapidFuzz (MIT): typos, parts, abbreviations. */
const char* motolii_find(Motolii* m, const char* query, const char* items, int limit);
/* The guides: lines across the picture, x upright and y level, at so many points from its left or top; a change is a
   step (motolii_later's "guide"). motolii_guides: a line each, "x 150" (until the next call). */
const char* motolii_guides(Motolii* m);
void motolii_close(Motolii* m);
int motolii_work_out(Motolii* m, const char* sum, double* is);     /* a sum typed in a number field (+ - * / and brackets), as After Effects', Figma's and Blender's take one, worked out by SQLite as the easings are; 0: it is not one */
const char* motolii_error(Motolii* m);                           /* why the last call that was not done was not */

const char* motolii_kind_of(const char* file);                     /* what kind of layer a file makes ("": none) */
int motolii_sets(const char* font, const char* words);             /* 1 if a text in that font file can be those words (any thread, while a document is open) */
const char* motolii_font_lacks(const char* font, const char* words);   /* the letters of those words that font file has not, each once ("": none), then a tab and the font they are all drawn in instead (a text of them is: "" none has them all); any thread, until its next call */
int motolii_type_frame(const char* font, const char* words, int w, int h, float most, unsigned char* grey);   /* those words in that font file white on black, as large as they fit (no larger than size most, when more than 0), w * h bytes (any thread, while a document is open); 0: not drawn */
int motolii_map(const float* points, int n, int dims, double* xy);   /* n points of dims numbers each laid on a plane, the alike near (t-SNE): 2n numbers, x and y from 0 to 1 (any thread); 0: fewer than 4 */
int motolii_grid(const double* xy, int n, int cols, int rows, int* cell);   /* those n places (x, y from 0 to 1) each a cell of a cols x rows grid, the nearest for them all (row * cols + column; any thread); 0: not laid */
int motolii_likeness(const char* model, const unsigned char* rgba, int n, int dims, float* out);   /* n pictures (224 square, RGBA) each told as dims numbers, one long, by a CLIP image encoder in an ONNX file (any thread); 0: not told */
int motolii_thumbnail_at(const char* video, const char* png, int wide, double fraction);   /* the same, a picture that far along the video (0 to 1) */
int motolii_thumbnail_seconds(const char* video, const char* png, int wide, double seconds);   /* the same, the picture so many seconds in */
const char* motolii_media_info(const char* file);   /* what a media file is, GStreamer's discoverer: "wide high rate seconds format" ("": cannot be read; until the next call on this thread) */
const char* motolii_flashes(const char* video, const char* folder);   /* a video's flashes and patterns that may cause seizures, as EA's IRIS tells them (video_flash_check.cpp): the path of the result.json it wrote under that folder, its frameData.json beside it ("": not read; any thread, one at a time; until the next call on this thread) */
const char* motolii_font_tags(const char* path);   /* a font file's kinds as CoreText reads them: serif sans script mono bold light italic symbols ornaments, and the languages beyond Latin it has (japanese korean chinese russian greek arabic hebrew thai hindi) */
int motolii_add(Motolii* m, const char* kind, const char* file);   /* a new layer (kind "": what the file makes), on from the stage's present moment: its number (0: not made) */
int motolii_remove(Motolii* m, int layer);
int motolii_set(Motolii* m, int layer, const char* name, double number);          /* a value that stays */
int motolii_say(Motolii* m, int layer, const char* name, const char* word);
int motolii_key(Motolii* m, int layer, const char* name, double at, double number);   /* a key at a moment */
int motolii_midi(Motolii* m, int layer, const char* name, const char* file, const char* kind, int channel, double bpm);   /* a MIDI file's notes as keys of a value, held, as om_midi keys them: kind velocity (0..1), pitch, count, on (1/0) or bool; channel -1: any; bpm: the file's beats played at it (0: the file's own) */
/* The stretch from the key at a moment to the next key is itself defined: how the value goes there. An easing is a name
   and up to four numbers ("smooth", "hold", "wiggle 3 0.2"). An easing of one's own is an expression (SQLite's) in u (how
   far through the stretch, 0 to 1), t (seconds into it), d (its length), a and b (the two keys' values), p1 to p4
   (the numbers said with it); it is taken only if it begins at a and ends at b. */
int motolii_easing(Motolii* m, int layer, const char* name, double at, const char* easing);
/* The effects a layer may be given, "name\tvalue\tlabel" one to a line (label: what it is for, the shelf's kind) (until the next call); one put on a layer at a moment,
   or taken off if it is on (its keys too), one step. Its card shows while it is on (motolii_cards). */
const char* motolii_effect_names(Motolii* m);
int motolii_effect(Motolii* m, int layer, const char* name, double at);
const char* motolii_easing_of(Motolii* m, int layer, const char* name, double at);   /* the easing of the stretch that begins at that key, as it is said ("": no key there; until the next call) */
const char* motolii_layer_stretches(Motolii* m, int layer);   /* every stretch of a layer's keyed values, a line each: "from\tto\tway" (until the next call) */
const char* motolii_easings(Motolii* m);
const char* motolii_easing_names(Motolii* m);                         /* the names alone, with spaces between: the nine kinds, then the easings defined here (until the next call) */
const char* motolii_easing_numbers(Motolii* m, const char* kind);   /* a kind's numbers as a hand takes them: name, lowest, highest for each ("seed 1 999 grain 0 0.5 ..."); "" for a kind with none or an easing defined in the document */
double motolii_easing_at(Motolii* m, const char* easing, double u);      /* how an easing goes, one of the nine kinds or one defined in the document: how far (0 at its beginning, 1 at its end) at u of the way through */                              /* the names of the easings the document knows (until the next call) */
int motolii_shows(Motolii* m, int layer, const char* name, double at, double* is);   /* as the stage shows it: 2 driven (by a relation, a behaviour), 1 its own, 0 none */
/* What a shell reads to draw its lists. motolii_layers: the numbers of the layers there are (as many as there is room
   for; it returns how many there are). motolii_word: a layer's word by name (kind, file, shape, blend, text, fill; ""
   if it has none; until the next call), or by "name" what it is called where layers are listed (a text by its
   words, a shape by its shape, a file by its name). motolii_lasts: how long a layer is on, in seconds (below 0: for good).
   motolii_key_times: the moments of a value's keys (none if the value stays). */
int motolii_layers(Motolii* m, int* layers, int room);
const char* motolii_word(Motolii* m, int layer, const char* name);
double motolii_lasts(Motolii* m, int layer);
int motolii_key_times(Motolii* m, int layer, const char* name, double* at, int room);
int motolii_layer_key_times(Motolii* m, int layer, double* at, int room);   /* every key moment of any of a layer's values, each once, in time (as many as there are; room: how many at holds) */
/* How a layer moves over a while, as its copy is placed (its script's and expressions' laying and its keys all told), n moments
   from `from` to before `to`: path[4i..4i+3] = where it is (x, y, units of the stage), how far it is turned (degrees) and
   how large (a share of its own size). For a shell's small preview that plays by itself. 0: there is no such layer. */
int motolii_path(Motolii* m, int layer, int copy, double from, double to, int n, double* path);
int motolii_path3(Motolii* m, int layer, int copy, double from, double to, int n, double* path);   /* the same in the round: x, y, z (units of the stage) and how large */
/* A layer dragged: drag_start, drag_update, drag_end (Flutter's GestureDetector onPanStart/Update/End): the one form
   of everything a pointer drags. What is dragged shows at once and is not the document's until drag_end; then it is one
   step (keep 0: nothing happened). The reckoning is the inside's: a shell says where the pointer is, never what the
   document is to hold.
     by "place"          dragged on the stage: a, b = how far the pointer has gone since drag_start, in points of the
                         picture (right, down); the layer stays under the pointer at its own depth
     by "bar"            its bar slid on the timeline: a = how many seconds later it comes on
     by "head", "tail"   its bar cut at an end: a = how many seconds later that end is (a video cut at its head goes on
                         showing at each moment what it showed there)
     by a value's name   that number dragged: a = what it is now
   motolii_drag_start on the layer already dragged goes on with the same drag. */
int motolii_drag_start(Motolii* m, int layer);
int motolii_drag_update(Motolii* m, const char* by, double a, double b);
double motolii_point(Motolii* m);                                  /* points of the picture to one unit of the stage, at z 0 */
const char* motolii_reading(Motolii* m, int layer, const char* name);  /* how a hand reads a value: "times from" (shown = value x times + from) */
/* What a hand does to a value at a moment, by the document's own rules: the value changed there (see
   motolii_keying for what that is to a value with keys and to one without). motolii_moving: the names of a layer's
   values that take keys, with spaces between (until the next call). */
int motolii_keying(Motolii* m, int on);                            /* on: every value a hand changes or carries gets a key at that moment, and its first key, if later than the moment this was turned on, leaves what it was as a key there, so it travels from there; off (as a document is opened): a value with keys gets a key where it is changed, one without stays as it is changed; below 0: only asks. Returns whether it is on now */
const char* motolii_moving(Motolii* m, int layer);
/* motolii_values: the names of all a layer's values, with spaces between (until the next call). motolii_range: a number
   value's lowest and highest (0: it has no such number). */
const char* motolii_values(Motolii* m, int layer);
int motolii_range(Motolii* m, int layer, const char* name, double* low, double* high);
/* The cards a maker sees a layer's values on, besides where it is and its fill: "title: name name; title: name" (until
   the next call). A value added to the document's cards is shown by a shell that reads this, with nothing of its own. */
const char* motolii_cards(Motolii* m, int layer);
const char* motolii_cards_more(Motolii* m, int layer);   /* the cards it may be given and is not shown: asked for by the maker (title: names; ...) */
/* How a value is shown to a hand: "look\tunit\tplain name\tlow\thigh\tfold" (empty: as its range says; until the next
   call). The look is count, onoff, angle, stage (a length of the stage, shown in points of the picture), down (one up the stage, shown down it), share (0 to 1,
   shown in hundredths), colour, colours, numbers, layer, seed or none; low and high the span its knob covers, in the
   document's own units; fold the name of the fold it lies in on its card (empty: not folded). */
const char* motolii_shown(Motolii* m, const char* name);
/* Pictures in one call: motolii_create_scripts says each create script's name and what it makes ("name\twhat", one to a line, until
   the next call; a closed pack "name\twhat\tprogram\tpath", what it was written for and its file: the Program shelf's); motolii_create makes one at the stage's present moment, as one step, and says the new layer (0: not). */
const char* motolii_create_scripts(Motolii* m);
/* The shelf's presets (a layer's values, effects and keys, all but what it is, holds and where it lies, kept as a
   file of its own): "name\tpath\tlabel\tpicture", one to a line, until the next call. */
const char* motolii_presets(Motolii* m);
int motolii_create(Motolii* m, const char* script);
/* The whole-screen effects on the shelf ("name\tpath\tlabel\tpicture\thome\tsame\tabout\ttags", one to a line, tags what it is read from it (isf.h isf_tags), label as the file's "// --label:" says;
   picture its tile ("" none yet), home where one drawn for it goes, same "same" when it is seen to change nothing (document/recipes.h doc_tile); until the next call): the stage's script is the
   paths of those on it, with spaces between, the first nearest the picture. AviUtl2's scripts after them (aviutl_scripts/,
   to any depth; an @ file's each "file#name"), each for a layer's fx. */
const char* motolii_effects(Motolii* m);
/* A file or folder the shelves read from was written, put in or taken out (the window's own watch says so, or a hand
   asks): the shelves, effects, scripts and create scripts ask their files again at their next use, and not before. */
void motolii_files_changed(void);
/* The motions a layer may be given (Cavalry's Animators: "name\tpath\tlabel", one to a line, until the next call): a layer's
   script is the path of the one it has (a text given one moves letter by letter). */
const char* motolii_animators(Motolii* m);
/* The relations written as files (a .js file each in relations/): "name\tfile", one to a line, as the animators. */
const char* motolii_relations(Motolii* m);
/* What the inside's hand has spent its time on since it was opened (a line of words, for measuring). */
const char* motolii_spent(Motolii* m);
/* Whether the inside is telling the stage a moment just now (the document held): a shell that reads each picture may
   leave this picture's reading out rather than wait (it is asked without the document, at once). */
/* What the document's steps changed since last asked, a line each ("layers" when a layer came or went, then "layer
   name" per value; asking forgets them), and the names of the values that change what cards a layer has. */
const char* motolii_shaping(Motolii* m);
/* A change asked without waiting for the hand (say, set, drag_start, drag_update, duck, drag_end, undo, redo, together: number is drag_end's keep and
   together's begin 1 / end 0; drag_update: name is by and number a, as motolii_drag_update, or name "effect" and word an effect file, shown on
   the dragged layer and not the document's until drag_end, and then not put on; duck: a video's volume keyed down 12 dB while
   another video is louder than -30 dB, Audacity's Auto Duck; layer -1: the layer the last add made; set with word "last_added": the number is that layer,
   as a value naming a layer; relate: the layers in word (numbers) put in the relation `layer` as they show now; free: the layer out of the
   relation `number`, as if at strength 0 for good: back to the relation under it, or its own value; lead: the relation `layer` led by the layer `number`, nothing moving; release: the relation
   `layer` let go, each of its layers where it shows now; key: a key of `name` at the moment in word holding number): queued in order behind all others, a ticket said at once. motolii_answer: -1 not done
   yet, 0 refused (motolii_answer_why says why, until the next answer), 1 done; an answer is said once. */
int motolii_later(Motolii* m, const char* call, int layer, const char* name, const char* word, double number);
int motolii_answer(Motolii* m, int ticket);
const char* motolii_answer_why(Motolii* m);
const char* motolii_words(Motolii* m, int layer, const char* name);   /* the words a value of a layer may be, with spaces between ("": any, or it is not a word; until the next call) */
/* One act that is several calls (a value changed and its key put): the changes made from motolii_together(m, 1) to
   motolii_together(m, 0) are one step of undo, and if one of them is refused none of them is made (0 comes back).
   Acts may lie one within another: the outermost is the step. */
int motolii_together(Motolii* m, int on);
int motolii_undo(Motolii* m);

double motolii_seconds(Motolii* m);                                /* how long the document runs */
int motolii_at(Motolii* m, double seconds);                        /* the stage's moment: sent, not waited for (a later one replaces it); what was drawn, and when, motolii_drawn_at */
int motolii_pack(Motolii* m, const char* folder, const char* name);   /* the document (as name.motolii) and the files its layers are made of, copied into a folder of their own, the copy's words told their names there: how many files (-1: not) */
int motolii_poster(Motolii* m, const char* png);                   /* the document's own picture (at its poster_at, else now), 256 on its longer side, written to png and kept in the document with its size and length */
const char* motolii_doc_properties(const char* path, const char* png);  /* a document read without opening it: "wide high seconds rate" as it was last kept, its picture written to png (null: not); "": none kept (any thread) */
int motolii_still(Motolii* m, const char* png);                    /* the stage as it is now, as a picture */
int motolii_export(Motolii* m, const char* mp4);                    /* the whole document as a video (.mp4 H.264, .mov HEVC, .gif, .png a picture each: render_draw.h), with its videos' sound; other calls are answered meanwhile (from another thread), but the document is not changed and nothing is held until it is done */
int motolii_rate(Motolii* m);                                      /* how many pictures a second that video has (a shell that counts in frames counts in these) */
char* motolii_snapshot(Motolii* m, int which, long since, long* version);   /* the window's pictures of the document (docs/app/BRIDGE.md), read without the document: 1 the document's (its own part and each layer's part newer than since), 2 the moment's; JSON, a copy freed with free(); *version: as of which */
void motolii_add_listener(Motolii* m, void (*listener)(int which));   /* the window's one listener, called (from the hand) when pictures are new: 1 the document's, 2 the moment's, 4 the cached frames (motolii_cache), 8 an answer to a change asked later (motolii_answer), or'd */
void motolii_watch(Motolii* m, int on);   /* on from the opening; while on, the window's (main) thread may not wait on the hand: a change it waits for, or a read waiting on the document over 2 ms, is kept */
const char* motolii_broken(Motolii* m);   /* what was kept since motolii_watch(1): one to a line, its clock time (hh:mm:ss.mmm) first, named and timed; "" none */
long motolii_broken_count(Motolii* m);   /* how many times the window's thread waited, or the inside took over 1/60 s for a picture (by its own clock or the GPU's), since it was watched (from the opening), read without waiting */
const char* motolii_list(Motolii* m);                              /* every fact of the document, a line each (until the next call) */
/* The stage's picture as it is drawn, for a shell to show without a copy. The inside keeps its own clock: it draws
   when something has changed or time is going on, and the shell asks only for the last finished picture.
   motolii_front: a CVPixelBufferRef on macOS, held for the caller (who lets it go); it and motolii_frames (how many
   pictures have been finished) may be called from any thread. */
void* motolii_front(Motolii* m);
/* The desk: the editing window's whole stage pane, w x h pixels, the picture drawn there instead of on the stage's own
   buffer (motolii_front keeps its last), the stage lying with its top left at x, y, `scale` pixels a point of it, and
   what lies off the stage seen round it, the picked layer marked over it (`point`: pixels a point of the screen the
   marks are sized in). w 0: off. Made again when its size changes. 1: on. */
void* motolii_desk_front(Motolii* m);
unsigned long long motolii_desk_frames(Motolii* m);
unsigned long long motolii_frames(Motolii* m);
/* Told on the hand's thread whenever a picture (the stage's or the desk's) is finished: `tell(with)`; then motolii_front
   or motolii_desk_front has it (Thermion's markTextureFrameAvailable: the shell asks nothing on a clock of its own). */
void motolii_finished(Motolii* m, void (*listener)(void*), void* with);
/* The stage's pictures kept on disk for playing (stage_cache.h): as stretches of frames at motolii_rate, "from to from to"
   ("" none), and how many times that has changed (read without waiting, as motolii_revision). */
const char* motolii_cache(Motolii* m);
/* A layer's effect cards' titles in the order its effects are laid, ";" between ("" none): ThorVG's own and files' alike.
   Moved with motolii_later "fx_move" (word: a title, number: places, up less than 0). */
const char* motolii_fx_titles(Motolii* m, int layer);
int motolii_play(Motolii* m, int playing);                         /* time goes on by the clock (and round again at the end), or stands */
double motolii_now(Motolii* m);                                    /* the stage's moment */
#ifdef __cplusplus
}
#endif
#endif
