//! A text layer's letters set as a web page sets them (text.h): the words go into a page whose CSS gives the font, and
//! each range of characters with declarations of its own becomes a span. Blitz resolves the CSS and Parley lays the
//! letters out (blitz-dom's stylo_to_parley.rs maps font-size, color, letter-spacing, baseline-shift and
//! font-variation-settings onto Parley's styles); skrifa draws each glyph at the run's variable-font axes, as Blitz's
//! painter does, and the outlines go back to ThorVG.

use std::ffi::{CStr, c_char};
use std::sync::Arc;

use blitz_dom::DocumentConfig;
use blitz_html::HtmlDocument;
use blitz_traits::shell::{ColorScheme, Viewport};
use parley::fontique::{Blob, FontInfoOverride};
use parley::{FontContext, PositionedLayoutItem};
use skrifa::instance::{LocationRef, Size};
use skrifa::outline::{DrawSettings, OutlinePen};
use skrifa::raw::types::F2Dot14;
use skrifa::{FontRef, MetadataProvider};

pub struct Text {
    verbs: Vec<u8>,
    points: Vec<f32>,
    lines: Vec<[f32; 5]>,
    letters: Vec<[f32; 5]>,
    colors: Vec<[f32; 8]>,
    /// The layer's font's ascent above the baseline and descent below it, at the size.
    font: [f32; 2],
}

/// The div's own color, which no range is expected to set: letters drawn in it take the layer's fill.
const UNSET: &str = "rgb(1 2 3 / 0.0039)";

fn escape(s: &str) -> String {
    s.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;").replace('"', "&quot;")
}

/// The font files ranges name as their font-family, `font-family: '/path/font.ttf'`, as the app names a font file it
/// loads (Flutter's FontLoader with the path as the family).
fn range_fonts(styles: &str) -> Vec<String> {
    let mut files: Vec<String> = styles
        .split(['\n', ';'])
        .filter_map(|d| d.trim().split_once(':').filter(|(k, _)| k.trim().ends_with("font-family")))
        .filter_map(|(_, v)| v.split(',').next())
        .map(|f| f.trim().trim_matches(['\'', '"']).to_string())
        .filter(|f| !f.is_empty())
        .collect();
    files.sort();
    files.dedup();
    files
}

/// The words as HTML: each run of characters that the same ranges cover, in a span with their declarations in order.
/// A range's font-family is followed by `fallback`, the layer's fonts, for the letters its font lacks.
fn spans(words: &str, styles: &str, fallback: &str) -> String {
    let n = words.chars().count();
    let ranges: Vec<(usize, usize, String)> = styles
        .lines()
        .filter_map(|l| {
            let mut it = l.trim().splitn(3, char::is_whitespace);
            let start: usize = it.next()?.parse().ok()?;
            let count: usize = it.next()?.parse().ok()?;
            let css = it.next().unwrap_or("").trim().split(';').map(|d| {
                let d = d.trim();
                if d.split_once(':').is_some_and(|(k, _)| k.trim() == "font-family") { format!("{d}, {fallback}") }
                else { d.to_string() }
            });
            Some((start.min(n), (start + count).min(n), css.collect::<Vec<_>>().join("; ")))
        })
        .filter(|r| r.0 < r.1 && !r.2.is_empty())
        .collect();
    let mut cuts: Vec<usize> = ranges.iter().flat_map(|r| [r.0, r.1]).chain([0, n]).collect();
    cuts.sort_unstable();
    cuts.dedup();
    let chars: Vec<char> = words.chars().collect();
    let mut html = String::new();
    for w in cuts.windows(2) {
        let piece: String = chars[w[0]..w[1]].iter().collect();
        let css: Vec<&str> = ranges.iter().filter(|r| r.0 <= w[0] && w[1] <= r.1).map(|r| r.2.as_str()).collect();
        if css.is_empty() {
            html += &escape(&piece);
        } else {
            html += &format!(r#"<span style="{}">{}</span>"#, escape(&css.join("; ")), escape(&piece));
        }
    }
    html
}

/// Collects one glyph's outline, moved to where it is set and slanted, and how far across its ink reaches.
struct Pen<'a> {
    verbs: &'a mut Vec<u8>,
    points: &'a mut Vec<f32>,
    at: (f32, f32),
    italic: f32,
    ink: (f32, f32),
}

impl Pen<'_> {
    fn put(&mut self, x: f32, y: f32) {
        // skrifa's y goes up from the baseline; the page's goes down.
        let (px, py) = (self.at.0 + x + self.italic * y, self.at.1 - y);
        self.ink = (self.ink.0.min(px), self.ink.1.max(px));
        self.points.extend([px, py]);
    }
}

impl OutlinePen for Pen<'_> {
    fn move_to(&mut self, x: f32, y: f32) {
        self.verbs.push(0);
        self.put(x, y);
    }
    fn line_to(&mut self, x: f32, y: f32) {
        self.verbs.push(1);
        self.put(x, y);
    }
    fn quad_to(&mut self, cx: f32, cy: f32, x: f32, y: f32) {
        // A quadratic as the cubic it equals.
        let n = self.points.len();
        let (sx, sy) = (self.points[n - 2], self.points[n - 1]);
        let (qx, qy) = (self.at.0 + cx + self.italic * cy, self.at.1 - cy);
        let (ex, ey) = (self.at.0 + x + self.italic * y, self.at.1 - y);
        self.verbs.push(2);
        self.points.extend([sx + 2.0 / 3.0 * (qx - sx), sy + 2.0 / 3.0 * (qy - sy)]);
        self.points.extend([ex + 2.0 / 3.0 * (qx - ex), ey + 2.0 / 3.0 * (qy - ey)]);
        self.put(x, y);
    }
    fn curve_to(&mut self, cx0: f32, cy0: f32, cx1: f32, cy1: f32, x: f32, y: f32) {
        self.verbs.push(2);
        self.put(cx0, cy0);
        self.put(cx1, cy1);
        self.put(x, y);
    }
    fn close(&mut self) {
        self.verbs.push(3);
    }
}

#[allow(clippy::too_many_arguments)]
pub fn set(words: &str, styles: &str, fonts: &[Vec<u8>], size: f32, line: f32, tracking: f32, slant: f32,
           wrap: f32, break_all: bool, align: f32) -> Option<Text> {
    let first = FontRef::new(fonts.first()?).ok()?;
    let m = first.metrics(Size::new(size), LocationRef::default());
    let mut ctx = FontContext::new();
    let mut families = Vec::new();
    for (i, bytes) in fonts.iter().enumerate() {
        let name = format!("motolii-font-{i}");
        let info = FontInfoOverride { family_name: Some(&name), ..Default::default() };
        if !ctx.collection.register_fonts(Blob::new(Arc::new(bytes.clone())), Some(info)).is_empty() {
            families.push(format!("'{name}'"));
        }
    }
    // Each font file a range names, registered under its path, so the range's declaration names it as it stands.
    for file in range_fonts(styles) {
        if let Ok(bytes) = std::fs::read(&file) {
            let info = FontInfoOverride { family_name: Some(&file), ..Default::default() };
            ctx.collection.register_fonts(Blob::new(Arc::new(bytes)), Some(info));
        }
    }
    let width = if wrap > 0.0 { format!("width: {wrap}px; white-space: pre-wrap;") } else {
        "width: max-content; white-space: pre;".into()
    };
    let breaks = if break_all { "word-break: break-all;" } else { "" };
    // Tracking in thousandths of an em, as After Effects' Character panel gives it.
    let tracking = tracking / 1000.0;
    let page = format!(
        r#"<html><body style="margin: 0"><div id="motolii-text" style="font-family: {}; font-size: {size}px; line-height: {line}; letter-spacing: {tracking}em; font-style: oblique {slant}deg; color: {UNSET}; {width} {breaks}">{}</div></body></html>"#,
        families.join(", "), spans(words, styles, &families.join(", ")));
    let config = DocumentConfig {
        viewport: Some(Viewport::new(1 << 15, 1 << 15, 1.0, ColorScheme::Light)),
        font_ctx: Some(ctx),
        ..Default::default()
    };
    let mut doc = HtmlDocument::from_html(&page, config);
    doc.resolve(0.0);
    let div = doc.get_element_by_id("motolii-text")?;
    let laid = &doc.get_node(div)?.element_data()?.inline_layout_data.as_ref()?.layout;

    // Each character's place by its first byte.
    let mut char_at = vec![usize::MAX; words.len() + 1];
    for (i, (b, _)) in words.char_indices().enumerate() {
        char_at[b] = i;
    }
    let mut out = Text { verbs: Vec::new(), points: Vec::new(), lines: Vec::new(),
                         letters: vec![[0.0; 5]; words.chars().count()], colors: Vec::new(),
                         font: [m.ascent, -m.descent] };
    // Each line is set in the widest one: a share of the way, where CSS's text-align has only three places.
    let widest = laid.lines().map(|l| l.metrics().advance).fold(0.0, f32::max);
    for (k, l) in laid.lines().enumerate() {
        let lm = l.metrics();
        let shift = align * (widest - lm.advance);
        let across = |x: f32| shift + x;
        let (mut up, mut down) = (0.0f32, 0.0f32);
        // Parley cuts a run (one font, one script) into glyph runs where the style changes, so each glyph run takes
        // the next clusters of its run that carry its style.
        let mut read = std::collections::HashMap::<usize, usize>::new();
        for item in l.items() {
            let PositionedLayoutItem::GlyphRun(g) = item else { continue };
            let run = g.run();
            let font = run.font();
            let Ok(face) = FontRef::from_index(font.data.data(), font.index) else { continue };
            let coords: Vec<F2Dot14> = run.normalized_coords().iter().map(|c| F2Dot14::from_bits(c.to_bits())).collect();
            let fm = run.font_metrics();
            (up, down) = (up.max(fm.ascent), down.max(fm.descent));
            let outlines = face.outline_glyphs();
            let settings = || DrawSettings::unhinted(Size::new(run.font_size()), LocationRef::new(&coords));
            // A slant the font has no face or axis for, made by leaning its letters (fontique's Synthesis).
            let italic = run.synthesis().skew().map_or(0.0, |a| a.to_radians().tan());
            let mut x = g.offset();
            let start = x;
            let from = read.entry(run.index()).or_insert(0);
            let clusters: Vec<_> = run.visual_clusters().skip(*from).take_while(|c| c.style_index() == g.style_index()).collect();
            *from += clusters.len();
            for cluster in clusters {
                let mut ink = (f32::INFINITY, f32::NEG_INFINITY);
                let mut gx = x;
                for glyph in cluster.glyphs() {
                    if let Some(o) = outlines.get(glyph.id.into()) {
                        let mut pen = Pen { verbs: &mut out.verbs, points: &mut out.points,
                                            at: (across(gx + glyph.x), g.baseline() + glyph.y), italic, ink };
                        let _ = o.draw(settings(), &mut pen);
                        ink = pen.ink;
                    }
                    gx += glyph.advance;
                }
                if let Some(&i) = char_at.get(cluster.text_range().start) && i != usize::MAX {
                    let (a, b) = if ink.0 <= ink.1 { ink } else { (0.0, 0.0) };
                    out.letters[i] = [across(x), cluster.advance(), a, b, k as f32];
                }
                x += cluster.advance();
            }
            let color = doc.get_node(g.style().brush.id).and_then(|n| n.primary_styles().map(|s| s.clone_color()));
            if let Some(c) = color {
                let c = *c.to_color_space(style::color::ColorSpace::Srgb).raw_components();
                if (c[0] - 1.0 / 255.0).abs() > 1e-3 || (c[3] - 0.0039).abs() > 1e-3 {
                    let (top, bottom) = (lm.block_min_coord, lm.block_max_coord);
                    out.colors.push([across(start), top, x - start, bottom - top, c[0], c[1], c[2], c[3]]);
                }
            }
        }
        out.lines.push([lm.baseline, up, down, across(0.0), lm.advance]);
    }
    Some(out)
}

unsafe fn text<'a>(p: *const c_char) -> &'a str {
    if p.is_null() { "" } else { unsafe { CStr::from_ptr(p) }.to_str().unwrap_or("") }
}

#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn motolii_text_new(words: *const c_char, styles: *const c_char, fonts: *const c_char,
                                          size: f32, line: f32, tracking: f32, slant: f32, wrap: f32,
                                          break_all: i32, align: f32) -> *mut Text {
    let (words, styles, fonts) = unsafe { (text(words), text(styles), text(fonts)) };
    let bytes: Vec<Vec<u8>> = fonts.lines().filter_map(|f| std::fs::read(f).ok()).collect();
    std::panic::catch_unwind(|| set(words, styles, &bytes, size, line, tracking, slant, wrap, break_all != 0,
                                    align))
        .ok()
        .flatten()
        .map_or(std::ptr::null_mut(), |t| Box::into_raw(Box::new(t)))
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn motolii_text_path(t: *const Text, verbs: *mut *const u8, verb_count: *mut i32,
                                           points: *mut *const f32, point_count: *mut i32) {
    let t = unsafe { &*t };
    unsafe {
        *verbs = t.verbs.as_ptr();
        *verb_count = t.verbs.len() as i32;
        *points = t.points.as_ptr();
        *point_count = (t.points.len() / 2) as i32;
    }
}

unsafe fn give<const N: usize>(all: &[[f32; N]], out: *mut f32) -> i32 {
    if !out.is_null() {
        unsafe { std::ptr::copy_nonoverlapping(all.as_ptr() as *const f32, out, all.len() * N) };
    }
    all.len() as i32
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn motolii_text_lines(t: *const Text, out: *mut f32) -> i32 { unsafe { give(&(*t).lines, out) } }

#[unsafe(no_mangle)]
pub unsafe extern "C" fn motolii_text_letters(t: *const Text, out: *mut f32) -> i32 {
    unsafe { give(&(*t).letters, out) }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn motolii_text_colors(t: *const Text, out: *mut f32) -> i32 { unsafe { give(&(*t).colors, out) } }

#[unsafe(no_mangle)]
pub unsafe extern "C" fn motolii_text_font(t: *const Text, ascent: *mut f32, descent: *mut f32) {
    unsafe { (*ascent, *descent) = ((*t).font[0], (*t).font[1]) };
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn motolii_text_free(t: *mut Text) {
    if !t.is_null() {
        drop(unsafe { Box::from_raw(t) });
    }
}

#[cfg(test)]
mod tests {
    use super::set;

    // CSS's own sense of the declarations (css-fonts-4 font-size percentages, css-color-4 hex colors): with "漢字" at
    // 150% and #ff8a3d, those two full-width letters take 1.5 em each where the hiragana take 1, the letter after them
    // moves along, and only they are listed as coloured.
    #[test]
    fn a_range_sets_its_letters_larger_and_coloured() {
        let font = std::fs::read(concat!(env!("CARGO_MANIFEST_DIR"), "/../../third_party/noto_sans_jp/NotoSansJP-Regular.otf"))
            .unwrap();
        let t = set("ひらがな漢字と", "4 2 font-size: 150%; color: #ff8a3d", &[font], 100.0, 1.2, 0.0, 0.0, 0.0, false,
                    0.0)
            .unwrap();
        let l = &t.letters;
        assert!((l[0][1] - 100.0).abs() < 0.5, "{l:?}");
        assert!((l[4][1] - 150.0).abs() < 0.5, "{l:?}");
        assert!((l[6][0] - (l[5][0] + l[5][1])).abs() < 0.5, "{l:?}");
        assert_eq!(t.colors.len(), 1, "{:?}", t.colors);
        let c = t.colors[0];
        assert!((c[0] - l[4][0]).abs() < 0.5 && (c[2] - 300.0).abs() < 0.5, "{c:?}");
        assert!((c[4] - 1.0).abs() < 0.01 && (c[5] - 138.0 / 255.0).abs() < 0.01 && (c[6] - 61.0 / 255.0).abs() < 0.01);
        assert!(t.verbs.len() > 20 && l[4][3] > l[4][2]);
    }

    // A range names a font file as its font-family, the way the app names a font file it loads (Flutter's FontLoader
    // with the path as the family): "M" in Roboto takes Roboto's advance, not Noto Sans JP's, and a letter Roboto lacks
    // ("あ") is still drawn, in the layer's font after it, as CSS falls back along font-family.
    #[test]
    fn a_range_sets_its_letters_in_a_font_file() {
        let jp = std::fs::read(concat!(env!("CARGO_MANIFEST_DIR"), "/../../third_party/noto_sans_jp/NotoSansJP-Regular.otf"))
            .unwrap();
        let roboto = concat!(env!("CARGO_MANIFEST_DIR"), "/../../third_party/filament_src/assets/fonts/Roboto-Medium.ttf");
        let plain = set("MMあ", "", std::slice::from_ref(&jp), 100.0, 1.2, 0.0, 0.0, 0.0, false, 0.0).unwrap();
        let t = set("MMあ", &format!("1 2 font-family: '{roboto}'"), &[jp], 100.0, 1.2, 0.0, 0.0, 0.0, false, 0.0)
            .unwrap();
        let (a, b) = (&plain.letters, &t.letters);
        assert!((a[0][1] - b[0][1]).abs() < 0.5, "{a:?} {b:?}");
        assert!((a[1][1] - b[1][1]).abs() > 1.0, "{a:?} {b:?}");
        assert!(b[2][3] > b[2][2], "{b:?}");
    }
}
