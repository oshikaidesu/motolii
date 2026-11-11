//! CSS animations, as posted on CodePen, moving the letters of a text layer.
//!
//! The page is the pen's own CSS and HTML. The [data-splitting] element the layer stands for holds the layer's words, cut
//! into the markup Splitting.js 1.x makes (read from its sources: core/splitting.js, utils/split-text.js, plugins/words.js,
//! plugins/chars.js; github.com/shshaw/Splitting), so the CSS meets the letters it was written for. Blitz (Stylo) runs the
//! animations; Motolii lays out and draws the letters, so it gives each letter's box, and gets back how the CSS moves it.
//! Checked against Chrome: docs/design/next_expressions.md, Q7.

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
        let config = DocumentConfig { viewport: Some(Viewport::new(w, h, 1.0, ColorScheme::Light)), ..Default::default() };
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

/// One pen's page, with one text layer's words in it.
pub struct Page {
    played: Played,
    /// The element each of Motolii's letters (or words) is, in its order; None for a space.
    letters: Vec<Option<NodeId>>,
}

fn escape(s: &str) -> String {
    s.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;").replace('"', "&quot;")
}

/// Splitting.js's markup for `text`: words, each its letters, a space between (plugins/words.js, plugins/chars.js).
fn split(text: &str) -> (String, usize, usize) {
    let words: Vec<&str> = text.split_whitespace().collect();
    let (mut out, mut chars) = (String::new(), 0);
    if text.starts_with(' ') { out.push(' '); }
    for (w, word) in words.iter().enumerate() {
        if w > 0 { out += r#"<span class="whitespace"> </span>"#; }
        let inner: String = word.chars().enumerate().map(|(j, c)| {
            let c = escape(&c.to_string());
            format!(r#"<span class="char" data-char="{c}" style="--char-index: {};">{c}</span>"#, chars + j)
        }).collect();
        chars += word.chars().count();
        out += &format!(r#"<span class="word" data-word="{}" style="--word-index: {w};">{inner}</span>"#, escape(word));
    }
    if text.ends_with(' ') && !words.is_empty() { out.push(' '); }
    (out, words.len(), chars)
}

/// The pen's HTML with the `nth` [data-splitting] element holding `text`, as Splitting.js leaves it: classes
/// "words chars splitting" and the totals as custom properties (core/splitting.js, utils/css-vars.js). A page with no
/// such element gets one, a div at the end. Only double-quoted class attributes are merged.
fn markup(html: &str, text: &str, nth: usize, font: f32) -> String {
    let in_tag = |at: usize| html[..at].rfind('<').map_or(false, |lt| html[..at].rfind('>').map_or(true, |gt| gt < lt));
    let Some(at) = html.match_indices("data-splitting").map(|(i, _)| i).filter(|&i| in_tag(i)).nth(nth) else {
        return markup(&format!("{html}<div data-splitting></div>"), text, 0, font);
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
    let (body, words, chars) = split(text);
    // The letters are drawn at the layer's size, so that is their font-size, and an em in the pen is as many pixels
    // as the drawn letters' em (css-values-4 §6.1.1: em is the element's computed font-size).
    let font = if font > 0.0 { format!(" font-size: {font}px;") } else { String::new() };
    format!(
        r#"{}<{name}{attrs} data-motolii class="{classes}words chars splitting" style="--word-total: {words}; --char-total: {chars};{font}">{body}{}"#,
        &html[..start], &html[close..])
}

/// Splitting.js 1.1.0's stylesheet, as released (engine/third_party/splitting/).
const SPLITTING: &str = include_str!("../../third_party/splitting/splitting.css");

impl Page {
    /// `css` and `html` as posted (either may be empty); `text` the layer's words; `nth` which [data-splitting] element
    /// the layer is; `by_words` when the layer is split into words, not letters; `size` the page, the project's size;
    /// `font` the size the layer's letters are drawn at, in pixels of the page (0: the pen's own).
    pub fn new(css: &str, html: &str, text: &str, nth: usize, by_words: bool, size: (u32, u32), font: f32) -> Page {
        // Splitting's recommended styles come first, as the pens that use it load them (inline-block letters, which
        // can then be transformed); the pen's own rules, later, win.
        let page = format!(
            "<!doctype html><html><head><meta charset=\"utf-8\"><style>{SPLITTING}</style><style>{css}</style></head><body>{}</body></html>",
            markup(html, text, nth, font));
        let played = Played::new(page, size);
        let doc = &played.doc;
        let pick = |sel: &str| doc.query_selector_all(sel).map(|v| v.to_vec()).unwrap_or_default();
        let (chars, words) = (pick("[data-motolii] .char"), pick("[data-motolii] .word"));
        // Motolii's letters are every character of the line, spaces too; its words are what lies between spaces
        // (stage/canvas/canvas_type.cpp).
        let letters = if by_words {
            text.split(' ').filter(|w| !w.is_empty()).enumerate().map(|(k, _)| words.get(k).copied()).collect()
        } else {
            let mut k = 0;
            text.chars().map(|c| if c.is_whitespace() { None } else { k += 1; chars.get(k - 1).copied() }).collect()
        };
        Page { played, letters }
    }

    pub fn letters(&self) -> usize { self.letters.len() }

    /// For each letter, its opacity and a 4 x 4 matrix (column-major, CSS pixels, y down) that moves it about its
    /// box's middle, as the CSS at `t` seconds moves it with everything around it. `boxes` is each letter's box, x y w h
    /// on the page, as Motolii lays it out, up and down its font's content area (a space's is not read).
    pub fn at(&mut self, t: f64, boxes: &[[f32; 4]]) -> Vec<[f64; 17]> {
        self.played.to(t);
        let doc = &self.played.doc;
        // A letter's box is as tall as its line-height, its half-leading above and below the content area
        // (CSS 2.1 §10.8.1), so its middle stays; `normal` keeps the content area (the font's line gap is not known).
        let boxes: Vec<[f32; 4]> = boxes.iter().zip(&self.letters).map(|(b, e)| {
            let Some(s) = e.and_then(|e| doc.get_node(e)).and_then(|n| n.primary_styles()) else { return *b };
            let f = s.get_font();
            let h = match &f.line_height {
                LineHeight::Normal => return *b,
                LineHeight::Number(n) => n.0 * f.font_size.computed_size().px(),
                LineHeight::Length(l) => l.0.px(),
            };
            [b[0], b[1] + 0.5 * (b[3] - h), b[2], h]
        }).collect();
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
            let m = boxes.get(i).map_or((0.0, 0.0), |b| ((b[0] + 0.5 * b[2]) as f64, (b[1] + 0.5 * b[3]) as f64));
            let about = Transform3D::translation(m.0, m.1, 0.0).then(&total).then(&Transform3D::translation(-m.0, -m.1, 0.0));
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
