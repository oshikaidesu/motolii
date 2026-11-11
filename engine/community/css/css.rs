//! CSS animations, as posted on CodePen, moving the letters of a text layer.
//!
//! The page is the pen's own CSS and HTML. The [data-splitting] element the layer stands for holds the layer's words, cut
//! into the markup Splitting.js 1.x makes (read from its sources: core/splitting.js, utils/split-text.js, plugins/words.js,
//! plugins/chars.js; github.com/shshaw/Splitting), so the CSS meets the letters it was written for. Blitz (Stylo) runs the
//! animations; Motolii lays out and draws the letters, so it gives each letter's box, and gets back how the CSS moves it.
//! Where the CSS lays the letters out itself (a flex or grid container above them), Blitz (Taffy) arranges boxes of the
//! letters' sizes, and the letters go where it puts them. Checked against Chrome: docs/design/next_expressions.md, Q7.

pub mod svg;

use std::collections::HashMap;
use std::ffi::{CStr, c_char};

use blitz_dom::{DocumentConfig, NodeId};
use blitz_html::HtmlDocument;
use blitz_traits::shell::{ColorScheme, Viewport};
use euclid::default::{Point2D, Rect, Size2D, Transform3D};
use style::properties::ComputedValues;
use style::values::animated::{Animate, Procedure};
use style::values::computed::transform::{Matrix3D, Transform, TransformOperation};
use style::values::computed::{CSSPixelLength as Length, LengthPercentage, LineHeight, Rotate};
use style::values::generics::transform::{GenericTransform, Scale, Translate};
use style::values::specified::box_::{DisplayInside, DisplayOutside};

/// How many device pixels the page has to the CSS pixel (Played::open).
const FINE: f32 = 32.0;

/// A page Blitz plays: its document as at `now` seconds.
pub(crate) struct Played {
    page: String,
    size: (u32, u32),
    pub doc: HtmlDocument,
    now: f64,
}

impl Played {
    pub fn new(page: String, size: (u32, u32)) -> Played {
        let doc = Played::open(&page, size);
        Played { page, size, doc, now: 0.0 }
    }

    fn open(page: &str, (w, h): (u32, u32)) -> HtmlDocument {
        // Blitz rounds the width of a run of inline boxes up to a whole device pixel (layout/inline.rs, `width.ceil()`),
        // half a CSS pixel a letter on average: so the page is shown at 32 device pixels to the CSS pixel (FINE). A power
        // of two, so that Blitz's own multiplying and dividing by it are exact; no more than Stylo's 60 app units to
        // the pixel, or Stylo divides by none of them (values/specified/border.rs, app_units_per_device_pixel).
        let config = DocumentConfig { viewport: Some(Viewport::new(w * FINE as u32, h * FINE as u32, FINE, ColorScheme::Light)), ..Default::default() };
        let mut doc = HtmlDocument::from_html(page, config);
        doc.resolve(0.0);
        doc
    }

    /// Plays to `t` seconds. Stylo moves an animation on by at most one iteration an update (iterate_if_necessary,
    /// servo/animation.rs), as Servo updates once a frame: so the page goes forward a frame (1/60 s) at a time, and back
    /// by starting again.
    pub fn to(&mut self, t: f64) {
        if t < self.now { self.doc = Played::open(&self.page, self.size); self.now = 0.0; }
        while self.now + 1.0 / 60.0 < t { self.now += 1.0 / 60.0; self.doc.resolve(self.now); }
        if t != self.now { self.now = t; self.doc.resolve(t); }
    }
}

/// What a page is made from (Page::new).
struct Source { css: String, html: String, text: String, nth: usize, by_words: bool, size: (u32, u32), font: f32 }

/// One pen's page, with one text layer's words in it.
pub struct Page {
    source: Source,
    played: Played,
    /// The element each of Motolii's letters (or words) is, in its order; None for a space.
    letters: Vec<Option<NodeId>>,
    /// The boxes that stand for each letter in the page's layout (`stand_in`), in the same order.
    stand_ins: Vec<Vec<NodeId>>,
    /// The [data-splitting] element the layer is, and the spaces between its words.
    text: Option<NodeId>,
    spaces: Vec<NodeId>,
    /// The letters' boxes the page was made with (none at first, when the page holds the letters themselves), and
    /// whether its spaces were made with no width.
    made_with: (Vec<[f32; 4]>, bool),
}

fn escape(s: &str) -> String {
    s.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;").replace('"', "&quot;")
}

/// A box of the size Motolii draws a letter at, standing in the page for the letter: Blitz has no font here, and the
/// letters are Motolii's to draw, so what the page lays out is their sizes.
/// It hangs from the top of its line, not on the baseline, so that a line of letters is as tall as the letters: on the
/// baseline, the line would also hold what a font keeps below it. Its size is a whole number of device pixels, so
/// that a row of them is exactly as wide as their sum, and the last does not fall to the next line by a rounding.
fn stand_in(w: f32, h: f32) -> String {
    let whole = |v: f32| (v.max(0.0) * FINE).round() / FINE;
    format!(r#"<motolii-letter style="display: inline-block; vertical-align: top; width: {}px; height: {}px;"></motolii-letter>"#, whole(w), whole(h))
}

/// Splitting.js's markup for `text`: words, each its letters, a space between (plugins/words.js, plugins/chars.js).
/// With `boxes` (Motolii's, x y w h, one per character or per word), each letter is a box of its size (`stand_in`), a
/// word's letters sharing the word's width, and a space is as wide as the gap between the boxes on its two sides, or
/// has no width if `no_spaces`.
fn split(text: &str, boxes: &[[f32; 4]], by_words: bool, no_spaces: bool) -> (String, usize, usize) {
    let words: Vec<&str> = text.split_whitespace().collect();
    let places: Vec<usize> = text.chars().enumerate().filter(|(_, c)| !c.is_whitespace()).map(|(i, _)| i).collect();
    // The box of letter `c` of the text, letter `j` of the `len` of word `w`.
    let piece = |c: usize, w: usize, j: usize, len: usize| -> Option<[f32; 4]> {
        if by_words { boxes.get(w).map(|b| [b[0] + b[2] * j as f32 / len as f32, b[1], b[2] / len as f32, b[3]]) }
        else { places.get(c).and_then(|&i| boxes.get(i)).copied() }
    };
    let (mut out, mut chars) = (String::new(), 0);
    if text.starts_with(' ') { out.push(' '); }
    for (w, word) in words.iter().enumerate() {
        let len = word.chars().count();
        if w > 0 {
            let before = words[w - 1].chars().count();
            let gap = piece(chars - 1, w - 1, before - 1, before).zip(piece(chars, w, 0, len))
                .map_or(" ".to_string(), |(a, b)| stand_in(if no_spaces { 0.0 } else { b[0] - a[0] - a[2] }, 0.0));
            out += &format!(r#"<span class="whitespace">{gap}</span>"#);
        }
        let inner: String = word.chars().enumerate().map(|(j, c)| {
            let c = escape(&c.to_string());
            let shown = piece(chars + j, w, j, len).map_or(c.clone(), |b| stand_in(b[2], b[3]));
            format!(r#"<span class="char" data-char="{c}" style="--char-index: {};">{shown}</span>"#, chars + j)
        }).collect();
        chars += len;
        out += &format!(r#"<span class="word" data-word="{}" style="--word-index: {w};">{inner}</span>"#, escape(word));
    }
    if text.ends_with(' ') && !words.is_empty() { out.push(' '); }
    (out, words.len(), chars)
}

/// The pen's HTML with the `nth` [data-splitting] element holding `text`, as Splitting.js leaves it: classes
/// "words chars splitting" and the totals as custom properties (core/splitting.js, utils/css-vars.js). A page with no
/// such element gets one, a div at the end. Only double-quoted class attributes are merged.
fn markup(html: &str, text: &str, nth: usize, font: f32, boxes: &[[f32; 4]], by_words: bool, no_spaces: bool) -> String {
    let in_tag = |at: usize| html[..at].rfind('<').map_or(false, |lt| html[..at].rfind('>').map_or(true, |gt| gt < lt));
    let Some(at) = html.match_indices("data-splitting").map(|(i, _)| i).filter(|&i| in_tag(i)).nth(nth) else {
        return markup(&format!("{html}<div data-splitting></div>"), text, 0, font, boxes, by_words, no_spaces);
    };
    let start = html[..at].rfind('<').unwrap();
    let name: String = html[start + 1..].chars().take_while(|c| c.is_alphanumeric() || *c == '-').collect();
    let open = start + html[start..].find('>').unwrap_or(html.len() - start);
    let close = html[open..].find(&format!("</{name}")).map_or(html.len(), |c| open + c);
    let mut attrs = html[start + 1 + name.len()..open].trim_end_matches('/').to_string();
    let mut classes = String::new();
    if let Some(c) = attrs.find("class=\"") {
        let end = attrs[c + 7..].find('"').map_or(attrs.len(), |e| c + 7 + e);
        classes = format!("{} ", &attrs[c + 7..end]);
        attrs.replace_range(c..(end + 1).min(attrs.len()), "");
    }
    let (body, words, chars) = split(text, boxes, by_words, no_spaces);
    // The letters are drawn at the layer's size, so that is their font-size, and an em in the pen is as many pixels
    // as the drawn letters' em (css-values-4 §6.1.1: em is the element's computed font-size).
    let font = if font > 0.0 { format!(" font-size: {font}px;") } else { String::new() };
    format!(
        r#"{}<{name}{attrs} data-motolii class="{classes}words chars splitting" style="--word-total: {words}; --char-total: {chars};{font}">{body}{}"#,
        &html[..start], &html[close..])
}

/// Splitting.js 1.1.0's stylesheet, as released (engine/third_party/splitting/).
const SPLITTING: &str = include_str!("../../third_party/splitting/splitting.css");

impl Source {
    /// The page played from 0, with the letters' `boxes` in it (none: a page that holds the letters themselves).
    fn open(self, (boxes, no_spaces): (Vec<[f32; 4]>, bool)) -> Page {
        // Splitting's recommended styles come first, as the pens that use it load them (inline-block letters, which
        // can then be transformed); the pen's own rules, later, win.
        let page = format!(
            "<!doctype html><html><head><meta charset=\"utf-8\"><style>{SPLITTING}</style><style>{}</style></head><body>{}</body></html>",
            self.css, markup(&self.html, &self.text, self.nth, self.font, &boxes, self.by_words, no_spaces));
        let played = Played::new(page, self.size);
        let doc = &played.doc;
        let pick = |sel: &str| doc.query_selector_all(sel).map(|v| v.to_vec()).unwrap_or_default();
        let (chars, words) = (pick("[data-motolii] .char"), pick("[data-motolii] .word"));
        let inside = |e: NodeId| -> Vec<NodeId> {
            pick("[data-motolii] .char motolii-letter").into_iter().filter(|&b| {
                let mut up = doc.get_node(b).and_then(|n| n.parent);
                while let Some(id) = up { if id == e { return true; } up = doc.get_node(id).and_then(|n| n.parent); }
                false
            }).collect()
        };
        // Motolii's letters are every character of the line, spaces too; its words are what lies between spaces
        // (stage/canvas/canvas_type.cpp).
        let letters: Vec<Option<NodeId>> = if self.by_words {
            self.text.split(' ').filter(|w| !w.is_empty()).enumerate().map(|(k, _)| words.get(k).copied()).collect()
        } else {
            let mut k = 0;
            self.text.chars().map(|c| if c.is_whitespace() { None } else { k += 1; chars.get(k - 1).copied() }).collect()
        };
        let stand_ins = letters.iter().map(|e| e.map_or(Vec::new(), inside)).collect();
        let (text, spaces) = (pick("[data-motolii]").first().copied(), pick("[data-motolii] .whitespace"));
        Page { source: self, played, letters, stand_ins, text, spaces, made_with: (boxes, no_spaces) }
    }
}

impl Page {
    /// `css` and `html` as posted (either may be empty); `text` the layer's words; `nth` which [data-splitting] element
    /// the layer is; `by_words` when the layer is split into words, not letters; `size` the page, the project's size;
    /// `font` the size the layer's letters are drawn at, in pixels of the page (0: the pen's own).
    pub fn new(css: &str, html: &str, text: &str, nth: usize, by_words: bool, size: (u32, u32), font: f32) -> Page {
        Source { css: css.into(), html: html.into(), text: text.into(), nth, by_words, size, font }.open((Vec::new(), false))
    }

    pub fn letters(&self) -> usize { self.letters.len() }

    /// Each letter's box made as tall as its line-height, its half-leading above and below the content area
    /// (CSS 2.1 §10.8.1), so its middle stays; `normal` keeps the content area (the font's line gap is not known).
    fn lines(&self, boxes: &[[f32; 4]]) -> Vec<[f32; 4]> {
        let doc = &self.played.doc;
        boxes.iter().zip(&self.letters).map(|(b, e)| {
            let Some(s) = e.and_then(|e| doc.get_node(e)).and_then(|n| n.primary_styles()) else { return *b };
            let f = s.get_font();
            let h = match &f.line_height {
                LineHeight::Normal => return *b,
                LineHeight::Number(n) => n.0 * f.font_size.computed_size().px(),
                LineHeight::Length(l) => l.0.px(),
            };
            [b[0], b[1] + 0.5 * (b[3] - h), b[2], h]
        }).collect()
    }

    /// Each letter's box where the page's own layout puts it, if the CSS lays the letters out: if the text, or an
    /// element in it above a letter (its word), is a flex or grid container. A container around the text, which a pen
    /// uses to centre it on its page, does not count: where the whole text stands is Motolii's. So the page arranges
    /// the letters among themselves, and the arrangement is set about the middle of the boxes as given.
    fn laid(&self, given: &[[f32; 4]]) -> Option<Vec<[f32; 4]>> {
        let doc = &self.played.doc;
        let lays_out = |e: NodeId| {
            let mut up = doc.get_node(e).and_then(|n| n.parent);
            while let Some(n) = up.and_then(|id| doc.get_node(id)) {
                let inside = n.primary_styles().map(|s| s.get_box().display.inside());
                if matches!(inside, Some(DisplayInside::Flex | DisplayInside::Grid)) { return true; }
                if Some(n.id) == self.text { break; }
                up = n.parent;
            }
            false
        };
        if !self.letters.iter().flatten().any(|&e| lays_out(e)) { return None; }
        // A box on the page, x0 y0 x1 y1: its place in its containing block, and that one's, up to the page (Taffy's
        // unrounded layout; Node::absolute_position sums the same, rounded to whole pixels).
        let on_page = |id: NodeId| -> Option<[f32; 4]> {
            let n = doc.get_node(id)?;
            let l = n.unrounded_layout();
            let (mut x, mut y) = (l.location.x, l.location.y);
            let mut up = n.containing_block();
            while let Some(p) = up.and_then(|id| doc.get_node(id)) {
                let (at, scroll) = (p.unrounded_layout().location, p.scroll_offset());
                (x, y) = (x + at.x - scroll.x as f32, y + at.y - scroll.y as f32);
                up = p.containing_block();
            }
            Some([x, y, x + l.size.width, y + l.size.height])
        };
        let around = |all: &mut [f32; 4], r: &[f32; 4]| *all = [all[0].min(r[0]), all[1].min(r[1]), all[2].max(r[2]), all[3].max(r[3])];
        let nothing = [f32::MAX, f32::MAX, f32::MIN, f32::MIN];
        let (mut page, mut ours) = (nothing, nothing);
        let spots: Vec<Option<[f32; 4]>> = self.stand_ins.iter().zip(given).map(|(ids, g)| {
            let mut r = nothing;
            for b in ids.iter().filter_map(|&id| on_page(id)) { around(&mut r, &b); }
            if r[0] > r[2] { return None; }
            around(&mut page, &r);
            around(&mut ours, &[g[0], g[1], g[0] + g[2], g[1] + g[3]]);
            Some(r)
        }).collect();
        let by = (0.5 * (ours[0] + ours[2] - page[0] - page[2]), 0.5 * (ours[1] + ours[3] - page[1] - page[3]));
        Some(spots.iter().zip(given).map(|(r, g)| r.map_or(*g, |r| {
            [0.5 * (r[0] + r[2]) + by.0 - 0.5 * g[2], 0.5 * (r[1] + r[3]) + by.1 - 0.5 * g[3], g[2], g[3]]
        })).collect())
    }

    /// For each letter, its opacity and a 4 x 4 matrix (column-major, CSS pixels, y down) that moves it about its
    /// box's middle, as the CSS at `t` seconds moves it with everything around it. `boxes` is each letter's box, x y w h
    /// on the page, as Motolii lays it out, up and down its font's content area (a space's is not read).
    pub fn at(&mut self, t: f64, boxes: &[[f32; 4]]) -> Vec<[f64; 17]> {
        self.played.to(t);
        let given = self.lines(boxes);
        // The page is made again with the letters' sizes in it once they are known, and when they change. A space that
        // is a flex or grid item has no width in a browser (its white space collapses: css-text-3 §4.1.2), and a box
        // standing for it would have: so the page is also made again when its spaces become items, or stop being.
        for _ in 0..2 {
            let doc = &self.played.doc;
            let no_spaces = self.spaces.iter().any(|&e| doc.get_node(e).and_then(|n| n.primary_styles())
                .is_some_and(|s| s.get_box().display.outside() != DisplayOutside::Inline));
            let (with, without) = &self.made_with;
            if *without == no_spaces && given.len() == with.len() && given.iter().zip(with).all(|(a, b)| (0..4).all(|k| (a[k] - b[k]).abs() <= 1e-3)) { break; }
            let source = std::mem::replace(&mut self.source, Source { css: String::new(), html: String::new(), text: String::new(), nth: 0, by_words: false, size: (0, 0), font: 0.0 });
            *self = source.open((given.clone(), no_spaces));
            self.played.to(t);
        }
        let boxes = self.laid(&given).unwrap_or_else(|| given.clone());
        let doc = &self.played.doc;
        // Each element's box: a letter's as given, any other's around the letters inside it.
        let mut around: HashMap<NodeId, [f32; 4]> = HashMap::new();
        for (i, e) in self.letters.iter().enumerate() {
            let (Some(e), Some(b)) = (e, boxes.get(i)) else { continue };
            let mut node = Some(*e);
            while let Some(id) = node {
                let r = around.entry(id).or_insert([f32::MAX, f32::MAX, f32::MIN, f32::MIN]);
                *r = [r[0].min(b[0]), r[1].min(b[1]), r[2].max(b[0] + b[2]), r[3].max(b[1] + b[3])];
                node = doc.get_node(id).and_then(|n| n.parent);
            }
        }
        self.letters.iter().enumerate().map(|(i, e)| {
            let mut out = [0.0; 17];
            let (mut opacity, mut total) = (1.0, Transform3D::<f64>::identity());
            let mut node = *e;
            while let Some(id) = node {
                let Some(n) = doc.get_node(id) else { break };
                if let (Some(styles), Some(r)) = (n.primary_styles(), around.get(&id)) {
                    opacity *= styles.get_effects().opacity as f64;
                    // A plain inline box is not a transformable element (drafts.csswg.org/css-transforms-1/
                    // #transformable-element): letters left inline, with no display set, do not move in a browser either.
                    if !styles.get_box().display.is_inline_flow() { total = total.then(&placed(&styles, r)); }
                }
                node = n.parent;
            }
            // From the middle of the box as given, by way of the box as the page lays it.
            let middle = |b: Option<&[f32; 4]>| b.map_or((0.0, 0.0), |b| ((b[0] + 0.5 * b[2]) as f64, (b[1] + 0.5 * b[3]) as f64));
            let (m, from) = (middle(boxes.get(i)), middle(given.get(i)));
            let about = Transform3D::translation(m.0, m.1, 0.0).then(&total).then(&Transform3D::translation(-from.0, -from.1, 0.0));
            out[0] = opacity;
            out[1..].copy_from_slice(&about.to_array());
            out
        }).collect()
    }
}

fn lp(px: f32) -> LengthPercentage { LengthPercentage::new_length(Length::new(px)) }

/// The element's current transformation matrix on the page, as CSS Transforms 2 §6 composes it: transform-origin,
/// translate, rotate, scale, transform, back by the origin (drafts.csswg.org/css-transforms-2/#ctm; Blitz's own
/// resolve_2d_transform does the same in 2D). `r` is its box, x0 y0 x1 y1 on the page.
pub(crate) fn placed(styles: &ComputedValues, r: &[f32; 4]) -> Transform3D<f64> {
    let b = styles.get_box();
    if matches!(b.translate, Translate::None) && matches!(b.rotate, Rotate::None) && matches!(b.scale, Scale::None)
        && b.transform.0.is_empty() { return Transform3D::identity(); }
    let (w, h) = (r[2] - r[0], r[3] - r[1]);
    let o = &b.transform_origin;
    let (ox, oy, oz) = (r[0] + o.horizontal.resolve(Length::new(w)).px(), r[1] + o.vertical.resolve(Length::new(h)).px(), o.depth.px());
    let mut ops = vec![TransformOperation::Translate3D(lp(ox), lp(oy), Length::new(oz))];
    if let Translate::Translate(x, y, z) = &b.translate { ops.push(TransformOperation::Translate3D(x.clone(), y.clone(), *z)); }
    match &b.rotate {
        Rotate::None => {}
        Rotate::Rotate(a) => ops.push(TransformOperation::Rotate(*a)),
        Rotate::Rotate3D(x, y, z, a) => ops.push(TransformOperation::Rotate3D(*x, *y, *z, *a)),
    }
    if let Scale::Scale(x, y, z) = &b.scale { ops.push(TransformOperation::Scale3D(*x, *y, *z)); }
    let size = Rect::new(Point2D::new(Length::new(0.), Length::new(0.)), Size2D::new(Length::new(w), Length::new(h)));
    ops.extend(resolved(&b.transform, &size));
    ops.push(TransformOperation::Translate3D(lp(-ox), lp(-oy), Length::new(-oz)));
    GenericTransform(ops.into()).to_transform_3d_matrix_f64(Some(&size)).map(|(m, _)| m).unwrap_or(Transform3D::identity())
}

/// A transform list with each InterpolateMatrix (keyframes that list different functions) resolved as Stylo's own TODO
/// says (values/generics/transform.rs, to_3d_matrix): each side made a matrix by the box, the two interpolated by Stylo's
/// Matrix3D::animate (decomposition, values/animated/transform.rs).
fn resolved(list: &Transform, size: &Rect<Length>) -> Vec<TransformOperation> {
    let matrix = |l: &Transform| {
        let m = GenericTransform(resolved(l, size).into()).to_transform_3d_matrix_f64(Some(size)).map(|(m, _)| m).unwrap_or(Transform3D::identity());
        Matrix3D::from(Transform3D::from_array(m.to_array().map(|v| v as f32)))
    };
    list.0.iter().map(|op| match op {
        TransformOperation::InterpolateMatrix { from_list, to_list, progress } => {
            let (a, b) = (matrix(from_list), matrix(to_list));
            TransformOperation::Matrix3D(a.animate(&b, Procedure::Interpolate { progress: progress.0 as f64 }).unwrap_or(a))
        }
        other => other.clone(),
    }).collect()
}

// The C side (css.h). A panic inside Blitz or Stylo is caught here and the page treated as not there.

unsafe fn text<'a>(p: *const c_char) -> &'a str {
    if p.is_null() { "" } else { unsafe { CStr::from_ptr(p) }.to_str().unwrap_or("") }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn motolii_css_new(css: *const c_char, html: *const c_char, words: *const c_char, nth: i32,
                                         by_words: i32, width: u32, height: u32, font: f32) -> *mut Page {
    let (css, html, words) = unsafe { (text(css), text(html), text(words)) };
    std::panic::catch_unwind(|| Page::new(css, html, words, nth.max(0) as usize, by_words != 0, (width, height), font))
        .map_or(std::ptr::null_mut(), |p| Box::into_raw(Box::new(p)))
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn motolii_css_letters(page: *const Page) -> i32 {
    unsafe { page.as_ref() }.map_or(0, |p| p.letters() as i32)
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn motolii_css_at(page: *mut Page, t: f64, boxes: *const f32, n: i32, out: *mut f64) -> i32 {
    let Some(p) = (unsafe { page.as_mut() }) else { return 0 };
    let n = n.max(0) as usize;
    let boxes: Vec<[f32; 4]> = unsafe { std::slice::from_raw_parts(boxes, n * 4) }.chunks(4).map(|c| [c[0], c[1], c[2], c[3]]).collect();
    let Ok(all) = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| p.at(t, &boxes))) else { return 0 };
    let out = unsafe { std::slice::from_raw_parts_mut(out, n * 17) };
    for (i, one) in all.iter().take(n).enumerate() { out[i * 17..i * 17 + 17].copy_from_slice(one); }
    all.len().min(n) as i32
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn motolii_css_free(page: *mut Page) {
    if !page.is_null() { drop(unsafe { Box::from_raw(page) }); }
}

// Where a pen's CSS lays the letters out, against Chrome 2026-11-11 (headless, a page 1280 x 633): the size Chrome gave
// each letter of a 64 px Helvetica (a space 17.78 px), and each letter's middle as Chrome laid it out, from the middle
// of all of them. The letters are given in one row, as Motolii lays a text. How to run them: docs/TESTING.md.
#[cfg(test)]
mod tests {
    use super::Page;

    fn laid(css: &str, text: &str, widths: &[f32], chrome: &[(f64, f64)]) {
        let css = format!("[data-splitting] {{ font: 700 64px Helvetica, Arial, sans-serif; }} {css}");
        let (mut x, mut k) = (100.0, 0);
        let boxes: Vec<[f32; 4]> = text.chars().map(|c| {
            let w = if c == ' ' { 17.78125 } else { k += 1; widths[k - 1] };
            x += w; [x - w, 300.0, w, 74.0]
        }).collect();
        let out = Page::new(&css, "", text, 0, false, (1280, 633), 64.0).at(0.0, &boxes);
        let ours: Vec<(f64, f64)> = text.chars().enumerate().filter(|(_, c)| *c != ' ')
            .map(|(i, _)| ((boxes[i][0] + 0.5 * boxes[i][2]) as f64 + out[i][13], 337.0 + out[i][14])).collect();
        let mid = |k: usize| { let v: Vec<f64> = ours.iter().map(|p| if k == 0 { p.0 } else { p.1 }).collect();
            0.5 * (v.iter().cloned().fold(f64::MAX, f64::min) + v.iter().cloned().fold(f64::MIN, f64::max)) };
        for (i, (p, q)) in ours.iter().zip(chrome).enumerate() {
            let (dx, dy) = (p.0 - mid(0) - q.0, p.1 - mid(1) - q.1);
            assert!(dx.abs() < 0.5 && dy.abs() < 0.5, "letter {i} of '{text}' is {dx:.2} {dy:.2} px from where Chrome lays it");
        }
    }

    #[test]
    fn flex_spreads_the_letters_of_a_word_as_chrome_does() {
        laid("[data-splitting] .word { display: flex; justify-content: space-between; width: 800px; }", "FLEXBOX",
             &[39.0938, 39.0938, 42.6875, 42.6875, 46.2188, 49.7812, 42.6875],
             &[(-379.555, 0.0), (-257.508, 0.0), (-133.648, 0.0), (-8.008, 0.0), (119.398, 0.0), (250.367, 0.0), (379.555, 0.0)]);
    }

    #[test]
    fn grid_lays_the_letters_in_rows_as_chrome_does() {
        laid("[data-splitting] .word { display: grid; grid-template-columns: repeat(2, 120px); gap: 30px 10px; }", "GRIDWORK",
             &[49.7812, 46.2188, 17.7812, 46.2188, 60.4062, 49.7812, 46.2188, 46.2188],
             &[(-57.0, -156.0), (71.219, -156.0), (-73.0, -52.0), (71.219, -52.0), (-51.688, 52.0), (73.0, 52.0), (-58.781, 156.0), (71.219, 156.0)]);
    }

    #[test]
    fn flex_wraps_words_with_no_width_for_the_spaces_as_chrome_does() {
        laid("[data-splitting] { display: flex; flex-wrap: wrap; justify-content: center; gap: 10px 40px; width: 600px; }",
             "the quick brown fox jumps over",
             &[21.3125, 39.0938, 35.5938, 39.0938, 39.0938, 17.7812, 35.5938, 35.5938, 39.0938, 24.9062, 39.0938, 49.7812, 39.0938,
               21.3125, 39.0938, 35.5938, 17.7812, 39.0938, 56.9062, 39.0938, 35.5938, 39.0938, 35.5938, 35.5938, 24.9062],
             &[(-179.141, -84.0), (-148.938, -84.0), (-111.594, -84.0), (5.75, -84.0), (44.844, -84.0), (73.281, -84.0),
               (99.969, -84.0), (135.562, -84.0), (-182.656, 0.0), (-150.656, 0.0), (-118.656, 0.0), (-74.219, 0.0),
               (-29.781, 0.0), (80.422, 0.0), (110.625, 0.0), (147.969, 0.0), (-191.156, 84.0), (-162.719, 84.0),
               (-114.719, 84.0), (-66.719, 84.0), (-29.375, 84.0), (87.969, 84.0), (125.312, 84.0), (160.906, 84.0), (191.156, 84.0)]);
    }
}
