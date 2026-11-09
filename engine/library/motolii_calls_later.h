// motolii_calls_later.h: part of motolii.mm. Read only through motolii.mm. Changes asked without waiting: queued behind the hand, a ticket said at once, answered later (motolii_later, motolii_answer); undo, redo.
// A change asked without waiting (a shell's hand that must not stand still while the hand works it): queued in order
// behind every other, a ticket said at once; motolii_answer says whether it is done (-1 not yet, 0 refused: then
// motolii_answer_why says why, 1 done; for add and make, the new thing). The calls: say, set, let_go (number: keep),
// undo, redo, together (number: begin 1, end 0: the end's answer is the step's), add (name: kind, word: file), make
// (word: recipe), duplicate (the answer is the new thing), split (number: at; the answer is the part after), copy and copy_style (word: a file), paste (word: a file, number: at) and paste_style (word: a file), remove, mark (number: at, word), guide (name: axis, number: at, word "off" takes it away), work
// (number: from, word: to), raise (number: places), sequence (number: overlap), key_here, unkey, stay (number: at), way
// (number: at, word: way), effect (number: at), hold (a hand takes hold of it), carry (name: by, number: a; name "effect": the effect file in word,
// shown on the held thing and not kept, doc_carry_effect), duck (its volume keyed down under the other sounds, Audacity's
// Auto Duck). A thing -1: the one the last add or make made.
int motolii_later(Motolii* m, const char* call, int thing, const char* name, const char* word, double number) {
    const std::string c = call ? call : "", n = name ? name : "", w = word ? word : "";
    int ticket = 0;
    {
        std::lock_guard<std::mutex> hold(m->asked_lock);
        ticket = ++m->tickets;
        m->lastPosted.clear();
        m->asked.push_back([m, c, n, w, thing = thing, number, ticket]() mutable {
            if (thing == -1) thing = m->made;   // (the thing the last add or make asked later made)
            const long rows = sqlite3_total_changes(m->d->file);
            int ok = 0;
            try {   // (a call that throws is refused with its words, not the end of the hand: the window waits on its ticket)
            if (c == "say") ok = changes(m, (int)doc_say(doc(m), thing, n.c_str(), w.c_str()));
            else if (c == "set") ok = changes(m, (int)doc_set(doc(m), thing, n.c_str(), w == "made" ? m->made : doc_macro_own(doc(m), thing, n.c_str(), doc(m).stage ? doc(m).stage->now : 0.0, number)));   // (word "made": the number is the thing the last add made, as a value that names a thing: a behaviour connected, a leader)
            else if (c == "let_go") ok = changes(m, (int)doc_let_go(doc(m), number != 0.0));
            else if (c == "duck") ok = changes(m, (int)duck(m, thing));   // (Audacity's Auto Duck: under the other sounds)
            else if (c == "carry") ok = (int)(n == "effect" ? doc_carry_effect(doc(m), w.c_str()) : doc_carry(doc(m), n.c_str(), number, 0.0));   // (name: by; an effect file in word)
            else if (c == "undo") ok = (int)doc_undo(doc(m));
            else if (c == "redo") ok = (int)doc_redo(doc(m));
            else if (c == "together") {
                ok = number < 0.0 ? (m->d->act ? (m->d->act_ok = false, (void)doc_acted(*m->d), m->revision.fetch_add(1, std::memory_order_release), picture_update(m), picture_moment(m), 1) : 0)   // (below 0: the open step given up, SQLite's rollback: a try on the stage, nothing kept; the window's pictures as they were again)
                    : number != 0.0 ? (doc_act(*m->d), m->d->act_together = true, 1) : (m->d->act ? (int)doc_acted(*m->d) : 0);
                if (!m->d->act) m->d->act_together = false;
            }
            else if (c == "add") ok = m->made = changes(m, doc_add(doc(m), n.c_str(), w.c_str()));   // (name: the kind, word: the file; the answer is the new thing)
            else if (c == "make") ok = m->made = changes(m, doc_make(doc(m), w.c_str()));
            else if (c == "door") ok = m->made = changes(m, doc_door(doc(m), w, thing));   // (word: code from the net; thing: the one picked, or 0)
            else if (c == "code") {   // (word: a program's file, saved)
                const std::string why = doc_code_saved(doc(m), w);
                ok = why.empty(), m->changed = true, doc(m).things_changed = true;   // (its knobs may be others now)
                if (!ok) m->trouble = why;
                m->revision.fetch_add(1, std::memory_order_release), picture_update(m), picture_moment(m);
            }
            else if (c == "duplicate") ok = m->made = changes(m, doc_copy_above(doc(m), thing));   // (the answer is the new thing)
            else if (c == "split") ok = m->made = changes(m, doc_split(doc(m), thing, number));   // (number: the moment; the answer is the part after it)
            else if (c == "extract") ok = changes(m, (int)doc_extract(doc(m)));   // (the work area taken out, the gap closed)
            else if (c == "align") {   // (word: how, then the things, each its number)
                std::istringstream said(w);
                std::string how;
                said >> how;
                std::vector<int> things;
                for (int t; said >> t;) things.push_back(t);
                ok = changes(m, (int)doc_align(doc(m), things, how));
            }
            else if (c == "flip") ok = changes(m, (int)doc_value_by(doc(m), thing, w == "y" ? "scale_y" : "scale_x", 0, -1));   // (word: x or y; its keys turned over too)
            else if (c == "time_stretch") {   // (word: where it is held, start, now or end, then the playhead; number: its new speed)
                std::istringstream said(w);
                std::string hold;
                double now = 0.0;
                said >> hold >> now;
                ok = changes(m, (int)doc_time_stretch(doc(m), thing, number, hold, now));
            }
            else if (c == "time_align") {   // (word: how, then the things, each its number; number: the playhead)
                std::istringstream said(w);
                std::string how;
                said >> how;
                std::vector<int> things;
                for (int t; said >> t;) things.push_back(t);
                ok = changes(m, (int)doc_time_align(doc(m), things, how, number));
            }
            else if (c == "reset") ok = changes(m, (int)doc_reset(doc(m), thing, w));   // (word: the values' names)
            else if (c == "fit") ok = changes(m, (int)doc_fit(doc(m), thing, w));   // (word: fit, fill or stretch)
            else if (c == "extract_sound") ok = m->made = changes(m, doc_extract_sound(doc(m), thing));   // (the answer is the copy that is heard)
            else if (c == "freehand") ok = m->made = changes(m, doc_freehand(doc(m), w.c_str()));   // (word: the outline's points of the picture, x y each; the answer is the new shape)
            else if (c == "outline") ok = changes(m, (int)doc_to_path(doc(m), thing));   // (Alight Motion's Convert to Outline: the shape a path of the outline it shows)
            else if (c == "curve") ok = m->made = changes(m, doc_curve(doc(m), w.c_str()));   // (word: how far the curve may stray, in points of the picture, then the hand's points, x y each; the answer is the new path)
            else if (c == "brush") ok = m->made = changes(m, doc_brush(doc(m), w.c_str(), thing));   // (word: the tool (0 pen, 1 brush, 2 fill, 3 eraser: of the thing's drawing), how wide, then each point of the picture x y and its pressure; the answer is the new shape, or the one erased from)
            else if (c == "copy") ok = (int)doc_look_save(doc(m), thing, w.c_str(), true);   // (word: the file it is kept in, whole)
            else if (c == "paste") ok = m->made = changes(m, doc_look_paste(doc(m), w.c_str(), number));   // (word: that file; number: when it begins; the answer is the new thing)
            else if (c == "copy_style") ok = (int)doc_look_save(doc(m), thing, w.c_str(), false, n);   // (its look: doc_looks.h; name: only these values, a card's)
            else if (c == "keep_look") ok = (int)doc_look_keep(doc(m), thing, w, n);   // (word: its name on the shelf; name: only these values, a card's)
            else if (c == "keep_element") ok = (int)doc_element_keep(doc(m), thing, w);   // (word: its name among the elements)
            else if (c == "fx_duplicate") ok = changes(m, (int)!doc_fx_duplicate(doc(m), thing, w).empty());   // (word: the effect's card's title: it put on again after it, its values with it)
            else if (c == "element") ok = m->made = changes(m, doc_element_add(doc(m), w.c_str(), number));   // (word: the element's file; number: when it begins; the answer is the new thing)
            else if (c == "follow_elements") ok = changes(m, doc_elements_follow(doc(m))) >= 0;   // (each element put in whose file was written since made as it is now)
            else if (c == "paste_style") ok = changes(m, (int)doc_look_put(doc(m), thing, w.c_str()));
            else if (c == "remove") ok = changes(m, (int)doc_remove(doc(m), thing));
            else if (c == "relate") ok = changes(m, (int)doc_relate(doc(m), thing, w.c_str(), m->now));
            else if (c == "fx_file") ok = changes(m, (int)doc_fx_file(doc(m), thing, w.c_str(), m->now));   // (an effect file put at the end of the thing's effects, or taken out; a transition runs from now)
            else if (c == "fx_out") ok = changes(m, (int)doc_fx_out(doc(m), thing, w.c_str()));   // (one of its effects taken off, by its card's title)
            else if (c == "fx_eye") ok = changes(m, (int)doc_fx_eye(doc(m), thing, w.c_str()));   // (one of its effects off, or on again: word its card's title)
            else if (c == "fx_move") ok = changes(m, (int)doc_fx_move(doc(m), thing, w.c_str(), (int)std::lround(number)));   // (one of its effects moved up or down its list)   // (the things in word put in the relation `thing` as they show now)
            else if (c == "lead") ok = changes(m, (int)doc_lead(doc(m), thing, (int)number, m->now));   // (the relation `thing` led by the thing `number`, nothing moving)
            else if (c == "free") ok = changes(m, (int)doc_free(doc(m), thing, (int)number, m->now, false));   // (a thing out of the relation `number`: back to what is under it, as the relation deleted does; only bake keeps where it shows)
            else if (c == "release") ok = changes(m, (int)doc_release(doc(m), thing, m->now));   // (the relation `thing` let go, each of its things where it shows now)
            else if (c == "mark") ok = changes(m, (int)doc_mark(doc(m), number, w.c_str()));
            else if (c == "mark_colour") ok = changes(m, (int)doc_mark_colour(doc(m), number, std::atoi(w.c_str())));   // (the mark at `number`: word its colour, 1 to 16; 0 none)
            else if (c == "guide") ok = changes(m, (int)doc_guide(doc(m), n.c_str(), number, w != "off"));
            else if (c == "work") ok = changes(m, (int)doc_work_is(doc(m), number, std::atof(w.c_str())));
            else if (c == "setting") ok = (int)doc_setting(doc(m), n.c_str(), w.c_str());   // (name: the window's choice kept with the document, word: what it is, "" none; not a step: doc_setting)
            else if (c == "size") {   // (word: "wide high", the stage's size the document says: opened at it again by the window)
                int wide = 0, high = 0;
                std::sscanf(w.c_str(), "%d %d", &wide, &high);
                char* say = doc_size_words(wide, high);
                ok = say ? changes(m, (int)doc_change(*m->d, say)) : (m->d->trouble = "a stage is from 16 to 8192 points each way, an even number of them", 0);
            }
            else if (c == "raise") ok = changes(m, (int)doc_raise(doc(m), thing, (int)number));
            else if (c == "sequence") ok = changes(m, (int)doc_sequence(doc(m), number, RATE));
            else if (c == "key_here") ok = changes(m, (int)doc_key_here(doc(m), thing, n.c_str(), number));
            else if (c == "key") ok = changes(m, (int)doc_key(doc(m), thing, n.c_str(), std::atof(w.c_str()), doc_macro_own(doc(m), thing, n.c_str(), std::atof(w.c_str()), number)));   // (word: the moment; number: what the key holds)
            else if (c == "unkey") ok = changes(m, (int)doc_unkey(doc(m), thing, n.c_str(), number));
            else if (c == "stay") ok = changes(m, (int)doc_stay(doc(m), thing, n.c_str(), number));
            else if (c == "way") ok = way_is(m, thing, n.c_str(), number, w.c_str());
            else if (c == "define") ok = define_is(m, n.c_str(), w.c_str());   // (name: the way; word: how it goes)
            else if (c == "show") {   // (what the open step has made so far, on the stage while a hand is still down: as doc_paths.h shows a picture placed, within its step)
                Doc& d = doc(m);
                ok = 1;
                if (d.act && d.act_unmatched) d.act_unmatched = false, doc_forget(d), ok = changes(m, (int)doc_match(d));
                if (d.act) d.changed.insert({thing, ""}), picture_update(m), picture_moment(m);   // (and the window's pictures of that thing, what changed being known only when the step ends: the bars and the numbers go with the hand too)
            }
            else if (c == "effect") ok = changes(m, (int)doc_effect(doc(m), thing, n.c_str(), number));
            else if (c == "pen") {   // (word: where the hand is and its handle, "x y hx hy", points of the picture; the answer is the path shape)
                double x = 0.0, y = 0.0, hx = 0.0, hy = 0.0;
                std::sscanf(w.c_str(), "%lf %lf %lf %lf", &x, &y, &hx, &hy);
                ok = m->made = changes(m, doc_pen(doc(m), thing, x, y, hx, hy));
            }
            else if (c == "live") ok = live_is(m);   // (the stage's live picture opened: answer 1 once it is)
            else if (c == "pick") ok = pick_is(m, thing, (int)number);   // (the thing picked in the window, number: the one under its hand)
            else if (c == "watch") {   // (word: the things the window shows the moving values of, spaced; their values in the moment's picture from the next)
                m->watched.clear();
                std::istringstream in(w);
                for (int t; in >> t;) m->watched.insert(t);
                picture_moment(m);   // (their values at once, not with the next picture)
                ok = 1, m->changed = true;
            }
            else if (c == "desk") {   // (word: "w h x y scale point", as motolii_desk; answer 1 once the desk's picture exists)
                int dw = 0, dh = 0;
                double x = 0.0, y = 0.0, sc = 0.0, pt = 0.0;
                std::sscanf(w.c_str(), "%d %d %lf %lf %lf %lf", &dw, &dh, &x, &y, &sc, &pt);
                ok = desk_is(m, dw, dh, x, y, sc, pt);
            }
            else if (c == "camera_view") ok = 1, m->second = !w.empty(), m->changed = true;   // (word: the Camera View tab is open; none: it is closed)
            else if (c == "eye") ok = eye_is(m, w.c_str());   // (word: where the window's working eye stands, as eye_is; none: the camera's)
            else if (c == "hold") ok = (int)doc_hold(doc(m), thing);   // (a hand takes hold: what it carries next is this thing's)
            else m->trouble = "a change asked later is one of: code, door, eye, camera_view, say, set, hold, carry, duck, let_go, undo, redo, together, add, make, pen, element, keep_element, follow_elements, fx_duplicate, duplicate, split, align, time_align, reset, fit, flip, extract_sound, freehand, brush, outline, copy, paste, copy_style, paste_style, keep_look, remove, mark, guide, work, raise, sequence, key_here, unkey, stay, way, effect, fx_file, fx_eye, fx_move, size, watch, pick, desk, live, relate, lead, free, release, setting";
            } catch (const std::exception& e) {
                ok = 0;
                std::fprintf(stderr, "motolii: %s threw: %s\n", c.c_str(), e.what());
                m->trouble = std::string(c) + " threw: " + e.what();
            }
            if (sqlite3_total_changes(m->d->file) != rows) m->revision.fetch_add(1, std::memory_order_release), picture_update(m), picture_moment(m);   // (the pictures new before the answer: the window reads what is so now)
            m->changed = true;
            { std::lock_guard<std::mutex> hold(m->asked_lock); m->answers[ticket] = {ok, ok ? std::string() : std::string(motolii_why(m))}; }
            { std::lock_guard<std::mutex> hold(m->pictureLock); m->pictureTold |= 8; }   // (and the window told an answer is there: motolii_tell, as Thermion's registry is told a request is done)
        });
    }
    m->asked_now.notify_one();
    return ticket;
}
int motolii_answer(Motolii* m, int ticket) {
    std::lock_guard<std::mutex> hold(m->asked_lock);
    const auto found = m->answers.find(ticket);
    if (found == m->answers.end()) return -1;
    const int ok = found->second.first;
    m->answered_why = found->second.second;
    m->answers.erase(found);
    return ok;
}
const char* motolii_answer_why(Motolii* m) { return m->answered_why.c_str(); }
int motolii_undo(Motolii* m) { return by_hand(m, [=] { return (int)(doc_undo(doc(m))); }); }
int motolii_redo(Motolii* m) { return by_hand(m, [=] { return (int)(doc_redo(doc(m))); }); }

