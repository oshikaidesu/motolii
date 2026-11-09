// presets.h: part of doc.h (a layer's preset kept and given to another). Read only through doc.h.
// A preset is a document of its own with one layer (layer 1): its keyframes as the document keeps them (keyframe: name, at,
// value, way; and the ways they go by), all but what the layer is and holds (kind, file, words, a shape's figure and path) and where it lies
// (x, y, z) and what it hangs on (parent), and its size and turn unless they move (keyed). Kept with SQLite's own
// copying across two files (ATTACH, insert ... select), given back the same way inside one act: the changes SQLite's
// session records, one step of undo as any other. A file it names in the library's folders or the maker's own is kept
// as {motolii}/... or {own}/... (doc_folders), so a preset made on one machine finds its effects on another (words only: a number stays a number).
// After Effects' animation presets (.ffx: effects and their keys), Alight Motion's Save as Preset and Paste Style.
static const char* const doc_preset_kept_out = "'kind','file','text','shape','path','x','y','z','parent','element'";   // (what it is: a shape's own figure and drawn path too)
static const char* const doc_preset_placed = "'size','scale_x','scale_y','rotate','rotate_x','rotate_y','orient'";   // (kept only when keyed: a pulse is a preset, a size is not)
static const char* const doc_preset_links = "'parent','mosh_with','copy_on','connect','connect_to','boolean_with','trail','morph_to'";   // (values that are another layer's number: kinds.h)

// The preset file attached as `preset` (read_only: as it is given, not written). One from before 2026-11-09 is read
// through a copy brought up to date (doc_upgrade: an attached file is renamed in the same words); a new one is version 1.
static std::string doc_preset_copy;   // (that copy while it is attached: removed by doc_preset_detach)
static bool doc_preset_attach(Doc& d, const char* path, bool read_only) {
    std::string at = path, why;
    sqlite3* old = nullptr;
    if (read_only && sqlite3_open_v2(path, &old, SQLITE_OPEN_READONLY, nullptr) == SQLITE_OK
        && sqlite3_exec(old, "select 1 from fact limit 0", nullptr, nullptr, nullptr) == SQLITE_OK) {
        std::error_code wrong;
        at = doc_preset_copy = (std::filesystem::temp_directory_path(wrong) / ("motolii_preset_" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()) + ".motolii")).string();
        std::filesystem::copy_file(path, at, std::filesystem::copy_options::overwrite_existing, wrong);
        read_only = false;
    }
    sqlite3_close(old);
    char* attach = read_only ? sqlite3_mprintf("attach database 'file:%q?mode=ro' as preset", at.c_str()) : sqlite3_mprintf("attach database %Q as preset", at.c_str());
    const bool ok = sqlite3_exec(d.file, attach, nullptr, nullptr, nullptr) == SQLITE_OK;
    sqlite3_free(attach);
    if (!ok) return d.error = sqlite3_errmsg(d.file), false;
    if (!read_only && !doc_upgrade(d.file, "preset", why)) return sqlite3_exec(d.file, "detach database preset", nullptr, nullptr, nullptr), d.error = why, false;
    return true;
}
static void doc_preset_detach(Doc& d) {
    sqlite3_exec(d.file, "detach database preset", nullptr, nullptr, nullptr);
    std::error_code wrong;
    if (!doc_preset_copy.empty()) std::filesystem::remove(doc_preset_copy, wrong), doc_preset_copy.clear();
}
// The library's folder and the maker's own, as a preset's words for them say them (doc_folders: the same order).
static std::pair<std::string, std::string> doc_preset_roots() {
    const auto at = doc_folders("looks");
    return {at[0].parent_path().string() + "/", at.size() > 1 ? at[1].parent_path().string() + "/" : std::string("\x01")};
}
// The layer's preset written as a file (a new document; one there before is written over); whole: all of it but what it
// hangs on (a copy, Edit > Copy: doc_preset_paste makes it a layer again).
// only: those values alone, their names with spaces between (a card's: its effect copied, as Alight Motion copies one).
static bool doc_preset_save(Doc& d, int layer, const char* path, bool whole = false, const std::string& only = "") {
    std::error_code wrong;
    std::filesystem::remove(path, wrong);
    bool ok = doc_preset_attach(d, path, false);
    if (!ok) return false;
    const auto roots = doc_preset_roots();
    char* copy = sqlite3_mprintf(
        "create table preset.keyframe(layer integer, name text, at numeric, value, easing text, primary key(layer, name, at)) without rowid;"
        "create table preset.easing(name text primary key, expression text) without rowid;"
        "create table preset.layer(id integer primary key autoincrement); insert into preset.layer(id) values(1);"
        "insert into preset.keyframe select 1, name, at, case typeof(value) when 'text' then replace(replace(value, %Q, '{motolii}/'), %Q, '{own}/') else value end, easing from main.keyframe as f where layer = %d and name not in (%s)"
        " and not (name in (%s) and (select count(*) from main.keyframe where layer = f.layer and name = f.name) = 1)"
        " and (%Q = '' or instr(' ' || %Q || ' ', ' ' || name || ' ') > 0);"
        "insert into preset.easing select * from main.easing where name in (select easing from preset.keyframe);", roots.first.c_str(), roots.second.c_str(), layer, whole ? "'parent'" : doc_preset_kept_out, whole ? "''" : doc_preset_placed, only.c_str(), only.c_str());
    ok = sqlite3_exec(d.file, copy, nullptr, nullptr, nullptr) == SQLITE_OK;
    sqlite3_free(copy);
    if (!ok) d.error = sqlite3_errmsg(d.file);
    // (the behaviours moving it, a wave, a noise, a random, a stagger, carried with it as layers 2, 3, ...; a relation,
    //  which ties it to others, is not: its _by left out. Whole, what a group holds too (the layers whose parent it is),
    //  and theirs, each telling another carried by its number here: Alight Motion copies a group with what is in it, as
    //  AbsentMotion's group is a scene of its own copied whole, its ElementActions.kt elementNodes)
    std::map<int, int> here{{layer, 1}};   // (a layer of the document: its number in the preset)
    std::vector<int> walk{layer};
    int next = 2;
    const auto carry = [&](int was) {
        char* one = sqlite3_mprintf("insert into preset.keyframe select %d, name, at, case typeof(value) when 'text' then replace(replace(value, %Q, '{motolii}/'), %Q, '{own}/') else value end, easing from main.keyframe where layer = %d;"
                                    "insert into preset.layer(id) values(%d);", next, roots.first.c_str(), roots.second.c_str(), was, next);
        ok = ok && sqlite3_exec(d.file, one, nullptr, nullptr, nullptr) == SQLITE_OK;
        sqlite3_free(one);
        here[was] = next++;
    };
    for (size_t i = 0; ok && i < walk.size(); ++i) {
        const int at = here[walk[i]];
        std::vector<int> by, held;
        doc_rows(d, sqlite3_mprintf("select distinct cast(value as integer) from preset.keyframe where layer = %d and name like '%%\\_by' escape '\\'", at), [&](sqlite3_stmt* q) { by.push_back(sqlite3_column_int(q, 0)); });
        for (const int b : by) {
            const bool carried = b && doc_word(d, b, "kind") == "behaviour" && doc_among("stagger oscillator noise random", doc_word(d, b, "file"));
            if (carried && !here.count(b)) carry(b);
            char* gone = carried ? nullptr : sqlite3_mprintf("delete from preset.keyframe where layer = %d and name like '%%\\_by' escape '\\' and value = %d;", at, b);
            ok = ok && (!gone || sqlite3_exec(d.file, gone, nullptr, nullptr, nullptr) == SQLITE_OK);
            sqlite3_free(gone);
        }
        if (whole) doc_rows(d, sqlite3_mprintf("select distinct layer from main.keyframe where name = 'parent' and cast(value as integer) = %d and layer != %d order by layer", walk[i], walk[i]), [&](sqlite3_stmt* q) { held.push_back(sqlite3_column_int(q, 0)); });
        for (const int h : held)
            if (!here.count(h)) carry(h), walk.push_back(h);
    }
    if (ok && here.size() > 1) {   // (each link from one carried to another carried told its number here; a link of a held layer to one not carried, gone)
        std::string cases, carried;
        for (const auto& [was, at] : here) cases += " when " + std::to_string(was) + " then " + std::to_string(at), carried += (carried.empty() ? "" : ",") + std::to_string(was);
        char* told = sqlite3_mprintf("delete from preset.keyframe where layer != 1 and name in (%s) and cast(value as integer) not in (%s);"
                                     "update preset.keyframe set value = case cast(value as integer)%s end where (name like '%%\\_by' escape '\\' or (layer != 1 and name in (%s))) and cast(value as integer) in (%s);",
                                     doc_preset_links, carried.c_str(), cases.c_str(), doc_preset_links, carried.c_str());
        ok = sqlite3_exec(d.file, told, nullptr, nullptr, nullptr) == SQLITE_OK;
        sqlite3_free(told);
    }
    doc_preset_detach(d);
    return ok;
}
// A preset file given to the layer, as one step: each value the preset says is the preset's (its keys and ways with it), the
// layer's own of those names gone first; the rest of the layer stays as it was.
static bool doc_preset_put(Doc& d, int layer, const char* path) {
    if (d.act) return d.error = "a preset is given by itself, not within another act", false;   // (SQLite attaches outside a transaction)
    const auto roots = doc_preset_roots();
    if (!doc_preset_attach(d, path, true)) return false;
    std::string carried;   // (each behaviour the preset carries made anew here, its own layer, and the layer's _by of it told the new one)
    sqlite3_stmt* q = nullptr;
    sqlite3_prepare_v2(d.file, "select distinct layer from preset.keyframe where layer != 1", -1, &q, nullptr);
    while (q && sqlite3_step(q) == SQLITE_ROW) {
        const int k = sqlite3_column_int(q, 0);
        char* one = sqlite3_mprintf("insert into layer default values; insert into keyframe select last_insert_rowid(), name, at, value, easing from preset.keyframe where layer = %d;"
                                    "update keyframe set value = (select max(id) from layer) where layer = %d and name in (select name from preset.keyframe where layer = 1 and name like '%%\\_by' escape '\\' and value = %d);", k, layer, k);
        carried += one;
        sqlite3_free(one);
    }
    sqlite3_finalize(q);
    const bool ok = doc_change(d, sqlite3_mprintf(
        "delete from keyframe where layer = %d and name in (select name from preset.keyframe where layer = 1) and name not in (%s);"
        "insert or replace into keyframe select %d, name, at, case typeof(value) when 'text' then replace(replace(value, '{motolii}/', %Q), '{own}/', %Q) else value end, easing from preset.keyframe where layer = 1 and name not in (%s);"
        "insert or ignore into easing select * from preset.easing;%s", layer, doc_preset_kept_out, layer, roots.first.c_str(), roots.second.c_str(), doc_preset_kept_out, carried.c_str()));
    doc_preset_detach(d);
    return ok;
}
// A copy (doc_preset_save whole) made a layer again, the newest number (Edit > Paste): it begins at `now`, its keys moved
// with it (as doc_keys_by moves a layer's), as Ableton Live pastes at the insert marker; the behaviours it carried and
// what a group held made anew after it, in their order, moved in time with it, each link among them told the new
// numbers. One step (with `also`, more said of them in it: SQL, the copy's layers as pasted_as says them; `before`,
// said first). into: its first layer one already here, kept as it is, what the copy holds made anew in it.
static int doc_preset_paste(Doc& d, const char* path, double now, const char* also = "", int into = 0, const char* before = "") {
    if (d.act) return d.error = "a copy is pasted by itself, not within another act", 0;   // (SQLite attaches outside a transaction)
    const auto roots = doc_preset_roots();
    if (!doc_preset_attach(d, path, true)) return 0;
    double was = 0;
    bool kind = false;
    sqlite3_stmt* q = nullptr;
    sqlite3_prepare_v2(d.file, "select name, value from preset.keyframe where layer = 1 and name in ('start', 'kind') and at = 0", -1, &q, nullptr);
    while (q && sqlite3_step(q) == SQLITE_ROW) {
        if (std::string((const char*)sqlite3_column_text(q, 0)) == "start") was = sqlite3_column_double(q, 1);
        else kind = true;
    }
    sqlite3_finalize(q);
    std::string made_all;   // (each layer of the copy a layer anew: its number there, its number here)
    sqlite3_prepare_v2(d.file, "select distinct layer from preset.keyframe order by layer", -1, &q, nullptr);
    while (q && sqlite3_step(q) == SQLITE_ROW) {
        const int k = sqlite3_column_int(q, 0);
        char* one = into && k == 1 ? sqlite3_mprintf("insert into pasted_as values(1, %d);", into) : sqlite3_mprintf("insert into layer default values; insert into pasted_as values(%d, last_insert_rowid());", k);
        made_all += one;
        sqlite3_free(one);
    }
    sqlite3_finalize(q);
    int made = 0;
    const double by = now - was;
    if (!kind) d.error = "that is no copy of a layer";
    else if (doc_change(d, sqlite3_mprintf(
                 "create temp table if not exists pasted_as(was integer, id integer); delete from pasted_as;%s%s"
                 "insert into keyframe select p.id, name, case when exists (select 1 from preset.keyframe as o where o.layer = f.layer and o.name = f.name and (o.at <> 0 or o.easing is not null)) then at + %!.17g else at end,"
                 " case when name = 'start' then max(0, value + %!.17g) when typeof(value) = 'text' then replace(replace(value, '{motolii}/', %Q), '{own}/', %Q) else value end, easing from preset.keyframe as f join pasted_as as p on p.was = f.layer where p.id != %d;"
                 "insert into keyframe(layer, name, at, value) select p.id, 'start', 0, max(0, %!.17g) from pasted_as as p where %!.17g > 0 and p.id != %d"   // (one that began at the first moment, said by nothing: begins later as much as the rest)
                 " and not exists (select 1 from preset.keyframe where layer = p.was and name = 'start') and (select value from preset.keyframe where layer = p.was and name = 'kind' and at = 0) <> 'behaviour';"
                 "update keyframe set value = (select id from pasted_as where was = cast(keyframe.value as integer)) where layer in (select id from pasted_as) and layer != %d"
                 " and (name like '%%\\_by' escape '\\' or (layer != (select id from pasted_as where was = 1) and name in (%s))) and cast(value as integer) in (select was from pasted_as);"
                 "insert or ignore into easing select * from preset.easing;%s", before, made_all.c_str(), by, by, roots.first.c_str(), roots.second.c_str(), into, by, by, into, into, doc_preset_links, also)))
        doc_rows(d, sqlite3_mprintf("select id from pasted_as where was = 1"), [&](sqlite3_stmt* row) { made = sqlite3_column_int(row, 0); });
    doc_preset_detach(d);
    return made;
}
// The layer's preset kept on the shelf by a name: in the maker's own presets folder (doc_folders), one of that name written
// over (Alight Motion's Save as Preset, After Effects' Save Animation Preset); only: these values alone, an effect's card
// (Alight Motion's preset of one effect), their keys with them.
static bool doc_preset_keep(Doc& d, int layer, const std::string& name, const std::string& only = "") {
    if (name.empty() || name.find_first_of("/\\:") != std::string::npos) return d.error = "a preset's name is a file's name", false;
    std::error_code wrong;
    const std::filesystem::path dir = doc_folders("looks").back();
    std::filesystem::create_directories(dir, wrong);
    std::string named = name;   // (an effect's: the first number its name has not yet, so each kept is another of its presets)
    for (int n = 1; !only.empty() && (named.empty() || named == name || std::filesystem::exists(dir / (named + ".motolii"))); ++n) named = name + " " + std::to_string(n);
    return doc_preset_save(d, layer, (dir / (named + ".motolii")).string().c_str(), false, only);
}
// The document and the files it is made of gathered in one folder, to be taken elsewhere whole (Alight Motion's project
// package; After Effects' Collect Files): the document copied as SQLite copies a database (VACUUM INTO), each file a layer
// is made of (its `file`, not one of the library's own nor the maker's: those are found on any machine) copied beside
// it, and the copy told its name there (a word read from the folder it is opened in). How many files were copied (-1: not).
static int doc_pack(Doc& d, const std::string& folder, const std::string& name) {
    std::error_code wrong;
    std::filesystem::create_directories(folder, wrong);
    const std::filesystem::path to = std::filesystem::path(folder) / (name + ".motolii");
    std::filesystem::remove(to, wrong);
    char* copy = sqlite3_mprintf("vacuum into %Q", to.string().c_str());
    const bool copied = sqlite3_exec(d.file, copy, nullptr, nullptr, nullptr) == SQLITE_OK;
    sqlite3_free(copy);
    if (!copied) return d.error = sqlite3_errmsg(d.file), -1;
    std::vector<std::string> files;
    doc_rows(d, sqlite3_mprintf("select distinct value from keyframe where name = 'file' and typeof(value) = 'text'"), [&](sqlite3_stmt* q) { files.push_back((const char*)sqlite3_column_text(q, 0)); });
    const auto roots = doc_preset_roots();
    sqlite3* pack = nullptr;
    if (sqlite3_open(to.string().c_str(), &pack) != SQLITE_OK) return sqlite3_close(pack), d.error = "the package could not be opened", -1;
    int n = 0;
    std::set<std::string> taken;
    for (const std::string& word : files) {
        const std::filesystem::path was = std::filesystem::absolute(word, wrong);
        const std::string whole = was.string();
        if (!std::filesystem::is_regular_file(was, wrong) || whole.rfind(roots.first, 0) == 0 || whole.rfind(roots.second, 0) == 0) continue;   // (a kind's own word, or the library's: nothing to carry)
        std::string named = was.filename().string();
        for (int k = 2; taken.count(named); ++k) named = was.stem().string() + " " + std::to_string(k) + was.extension().string();   // (two files of one name from two folders)
        taken.insert(named);
        if (!std::filesystem::copy_file(was, std::filesystem::path(folder) / named, std::filesystem::copy_options::overwrite_existing, wrong)) continue;
        char* told = sqlite3_mprintf("update keyframe set value = %Q where name = 'file' and value = %Q", named.c_str(), word.c_str());
        sqlite3_exec(pack, told, nullptr, nullptr, nullptr);
        sqlite3_free(told);
        ++n;
    }
    sqlite3_close(pack);
    return n;
}

// The presets on the shelf: looks/*.motolii in the library's folder and the maker's own (doc_folders), as the effects
// are ("name\tpath\tlabel\tpicture", one to a line): its name the file's, its picture the .png beside it. Then the
// elements, elements/*.motolii, labelled Element (Alight Motion's My Elements: doc_element_keep).
static std::string doc_preset_names() {
    std::string all;
    std::error_code wrong;
    for (const char* kind : {"looks", "elements"})
        for (const auto& f : doc_folder_files(kind, ".motolii")) {
            const std::filesystem::path picture = std::filesystem::path(f).replace_extension(".png");
            all += (all.empty() ? "" : "\n") + f.stem().string() + "\t" + f.string() + (kind[0] == 'l' ? "\tLook\t" : "\tElement\t") + (std::filesystem::exists(picture, wrong) ? picture.string() : "");
        }
    return all;
}
// The layer kept as an element by its name, whole, with what it holds (Alight Motion's Save to My Elements; AbsentMotion's
// saveToMyElements, ElementActions.kt): in the maker's own elements folder, one of that name written over.
static bool doc_element_keep(Doc& d, int layer, const std::string& name) {
    if (name.empty() || name.find_first_of("/\\:") != std::string::npos) return d.error = "an element's name is a file's name", false;
    std::error_code wrong;
    const std::filesystem::path dir = doc_folders("elements").back();
    std::filesystem::create_directories(dir, wrong);
    return doc_preset_save(d, layer, (dir / (name + ".motolii")).string().c_str(), true);
}
// When an element's file was last written (seconds), as an instance keeps it to know it has changed since.
static double doc_element_written(const std::string& path) {
    std::error_code wrong;
    const auto at = std::filesystem::last_write_time(path, wrong);
    return wrong ? -1.0 : std::chrono::duration<double>(at.time_since_epoch()).count();
}
// What each layer an element put in holds keeps of where it came from (said with the paste, as pasted_as says them):
// which of the element's layers it is (element_part), a text's words as the element said them (element_text: words
// of its own since are its own, kept when the element changes: an override, as a Figma instance keeps one), and on
// the first, when the file was written (element_at), its Re-timing and how long it is (element_length).
static std::string doc_element_marks(double written) {
    char* marks = sqlite3_mprintf("insert or replace into keyframe(layer, name, at, value) select id, 'element_part', 0, was from pasted_as where was != 1;"
                                  "insert or replace into keyframe(layer, name, at, value) select p.id, 'element_text', 0, f.value from pasted_as as p join preset.keyframe as f on f.layer = p.was and f.name = 'text' and f.at = 0;"
                                  "insert or replace into keyframe(layer, name, at, value) select id, 'element_at', 0, %!.17g from pasted_as where was = 1;"
                                  "delete from keyframe where layer = (select id from pasted_as where was = 1) and name in ('retime', 'retime_in', 'retime_out', 'element_length');"   // (and its Re-timing as the element says it, and how long the element is)
                                  "insert into keyframe(layer, name, at, value) select p.id, f.name, 0, f.value from pasted_as as p join preset.keyframe as f on f.layer = 1 and f.at = 0 and f.name in ('retime', 'retime_in', 'retime_out') where p.was = 1;"
                                  "insert into keyframe(layer, name, at, value) select p.id, 'element_length', 0, f.value from pasted_as as p join preset.keyframe as f on f.layer = 1 and f.at = 0 and f.name = 'duration' where p.was = 1;", written);
    std::string said = marks;
    sqlite3_free(marks);
    return said;
}
// An element put in at `now`, the newest layer, in the stage's middle, linked to its file (its `element`, the file as a
// preset says it: AbsentMotion's addElement, ElementActions.kt, an embedScene at the scene's centre with its link). One step.
static int doc_element_add(Doc& d, const char* path, double now) {
    const auto roots = doc_preset_roots();
    std::string word = path;
    for (const auto& [root, said] : {std::pair{roots.first, "{motolii}/"}, std::pair{roots.second, "{own}/"}})
        if (word.rfind(root, 0) == 0) word = said + word.substr(root.size());
    char* also = sqlite3_mprintf("delete from keyframe where layer = (select id from pasted_as where was = 1) and name in ('x', 'y', 'element');"
                                 "insert into keyframe(layer, name, at, value) select id, 'x', 0, 0 from pasted_as where was = 1 union all select id, 'y', 0, 0 from pasted_as where was = 1"
                                 " union all select id, 'element', 0, %Q from pasted_as where was = 1;%s", word.c_str(), doc_element_marks(doc_element_written(path)).c_str());
    const int made = doc_preset_paste(d, path, now, also);
    sqlite3_free(also);
    return made;
}
// Each element put in whose file was written since follows it (AbsentMotion's ProjectStore.kt withLinkedElements: a
// linked embedScene's scene replaced by the element's as it is now): what it held made anew from the file, it kept
// as it is (where it lies, when it begins), each text whose words are its own since given them again. One step each.
// How many followed.
static int doc_elements_follow(Doc& d) {
    const auto roots = doc_preset_roots();
    int n = 0;
    for (const int one : doc_layers(d)) {
        std::string path = doc_word(d, one, "element");
        if (path.empty()) continue;
        if (path.rfind("{motolii}/", 0) == 0) path = roots.first + path.substr(10);
        else if (path.rfind("{own}/", 0) == 0) path = roots.second + path.substr(6);
        const double written = doc_element_written(path);
        if (written < 0 || written == doc_number(d, one, "element_at", 0, -1)) continue;
        std::vector<int> held{one};   // (it and all it holds, and theirs)
        std::string gone, kept;
        for (size_t i = 0; i < held.size(); ++i)
            for (const int t : doc_layers(d))
                if (t != held[i] && (int)doc_number(d, t, "parent", 0, 0) == held[i] && std::find(held.begin(), held.end(), t) == held.end()) {
                    held.push_back(t);
                    char* g = sqlite3_mprintf("delete from keyframe where layer = %d;", t);
                    gone += g;
                    sqlite3_free(g);
                    const std::string words = doc_word(d, t, "text");
                    const int part = (int)doc_number(d, t, "element_part", 0, 0);
                    if (part && doc_word(d, t, "kind") == "text" && words != doc_word(d, t, "element_text")) {
                        char* k = sqlite3_mprintf("update keyframe set value = %Q where layer = (select id from pasted_as where was = %d) and name = 'text' and at = 0;", words.c_str(), part);
                        kept += k;
                        sqlite3_free(k);
                    }
                }
        const std::string also = doc_element_marks(written) + kept;
        n += doc_preset_paste(d, path.c_str(), doc_number(d, one, "start", 0, 0), also.c_str(), one, gone.c_str()) == one;
    }
    return n;
}
