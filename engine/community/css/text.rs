//! Typography engine for text layers (text.h):
//! - Horizontal typesetting via Blitz + Stylo + Parley (HarfRust + ICU4X) with
//!   OpenType features (`font-feature-settings`), Japanese kinsoku (`line-break`
//!   with `lang="ja"`), and hanging punctuation (`、。，．`).
//! - Vertical-rl typesetting via HarfRust (`Direction::TopToBottom` with OpenType
//!   `vert`/`vrt2`, `vpal`/`vhal`, and `vmtx`/`vorg`) with kinsoku and hanging
//!   punctuation.
//! - Font metadata (variable axes `fvar` and OpenType features `GSUB`/`GPOS`)
//!   read directly via `skrifa`.

use std::collections::{BTreeSet, HashMap};
use std::ffi::{CStr, c_char};
use std::str::FromStr;
use std::sync::Arc;

use blitz_dom::DocumentConfig;
use blitz_html::HtmlDocument;
use blitz_traits::shell::{ColorScheme, Viewport};
use harfrust::{Direction, Feature, Language, ShapeOptions, ShaperData, ShaperInstance, Tag as HbTag, UnicodeBuffer, Variation};
use parley::fontique::{Blob, FontInfoOverride};
use parley::{FontContext, PositionedLayoutItem};
use skrifa::instance::{LocationRef, Size};
use skrifa::outline::{DrawSettings, OutlinePen};
use skrifa::raw::TableProvider;
use skrifa::raw::types::F2Dot14;
use skrifa::{FontRef, MetadataProvider, Tag};

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

/// Characters allowed to hang past the line/column end when hanging punctuation is enabled.
fn is_hanging_punct(c: char) -> bool {
    matches!(c, '、' | '。' | '，' | '．' | '｡' | '､')
}

/// Line-start forbidden characters (行頭禁則) for vertical & hanging checks.
fn is_kinsoku_start(c: char, strict: bool) -> bool {
    let basic = matches!(
        c,
        '、' | '。' | '，' | '．' | '｡' | '､' | '）' | '」' | '』' | '】' | '〕' | '〉' | '》' | '］'
            | '｝' | ')' | ']' | '}' | '!' | '?' | '！' | '？' | '：' | '；' | ':' | ';' | '・' | 'ヽ'
            | 'ヾ' | 'ゝ' | 'ゞ' | '々' | 'ー' | '〜' | '～' | '…' | '‥'
    );
    if basic || !strict {
        return basic;
    }
    matches!(
        c,
        'ぁ' | 'ぃ' | 'ぅ' | 'ぇ' | 'ぉ' | 'っ' | 'ゃ' | 'ゅ' | 'ょ' | 'ゎ' | 'ァ' | 'ィ' | 'ゥ' | 'ェ'
            | 'ォ' | 'ッ' | 'ャ' | 'ュ' | 'ョ' | 'ヮ' | 'ヵ' | 'ヶ' | '‐' | '―'
    )
}

/// Line-end forbidden characters (行末禁則: opening brackets).
fn is_kinsoku_end(c: char) -> bool {
    matches!(c, '（' | '「' | '『' | '【' | '〔' | '〈' | '《' | '［' | '｛' | '(' | '[' | '{')
}

/// Parses OpenType feature strings from either CSS syntax (`"palt" 1, "kern" 0`)
/// or shorthand tag tokens (`palt -kern tnum`), returning normalized `(tag, value)` pairs.
fn parse_features(raw: &str) -> Vec<([u8; 4], u32)> {
    let mut out = Vec::new();
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return out;
    }
    for part in trimmed.split([',', ';']) {
        let p = part.trim();
        if p.is_empty() {
            continue;
        }
        let tokens: Vec<&str> = p.split_whitespace().collect();
        let mut i = 0;
        while i < tokens.len() {
            let tok = tokens[i];
            let (neg, clean) = if let Some(rest) = tok.strip_prefix('-') {
                (true, rest)
            } else {
                (false, tok)
            };
            let clean = clean.trim_matches(['"', '\'']);
            if clean.len() == 4 && clean.is_ascii() {
                let mut tag = [0u8; 4];
                tag.copy_from_slice(clean.as_bytes());
                let mut val = if neg { 0u32 } else { 1u32 };
                if !neg && i + 1 < tokens.len() {
                    match tokens[i + 1] {
                        "on" => {
                            val = 1;
                            i += 1;
                        }
                        "off" => {
                            val = 0;
                            i += 1;
                        }
                        n if n.parse::<u32>().is_ok() => {
                            val = n.parse().unwrap_or(1);
                            i += 1;
                        }
                        _ => {}
                    }
                }
                out.push((tag, val));
            }
            i += 1;
        }
    }
    out
}

fn format_css_features(feats: &[([u8; 4], u32)]) -> String {
    if feats.is_empty() {
        return String::new();
    }
    // Use single quotes because this embeds inside an HTML `style="..."` attribute.
    let items: Vec<String> = feats
        .iter()
        .map(|(tag, val)| format!("'{}' {val}", std::str::from_utf8(tag).unwrap_or("")))
        .collect();
    format!("font-feature-settings: {};", items.join(", "))
}

fn css_line_break(kinsoku: &str) -> &'static str {
    match kinsoku.trim() {
        "strict" => "strict",
        "loose" => "loose",
        "none" | "anywhere" => "anywhere",
        _ => "normal",
    }
}

/// The font files ranges name as their font-family, `font-family: '/path/font.ttf'`.
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

/// Matches Unicode character classes used by `@class` composite-font rules in `text_styles`.
fn char_matches_class(c: char, cls: &str) -> bool {
    let u = c as u32;
    let is_latin = matches!(u, 0x0041..=0x024F | 0x1E00..=0x1EFF | 0xFF21..=0xFF3A | 0xFF41..=0xFF5A);
    match cls {
        "kanji" => {
            matches!(u, 0x4E00..=0x9FFF | 0x3400..=0x4DBF | 0xF900..=0xFAFF | 0x3005 | 0x20000..=0x2A6DF)
        }
        "hiragana" => matches!(u, 0x3040..=0x309F),
        "katakana" => matches!(u, 0x30A0..=0x30FF | 0x31F0..=0x31FF | 0xFF66..=0xFF9F),
        "hangul" => matches!(u, 0xAC00..=0xD7AF | 0x1100..=0x11FF | 0x3130..=0x318F | 0xA960..=0xA97F | 0xD7B0..=0xD7FF),
        "upper" => is_latin && c.is_uppercase(),
        "lower" => is_latin && c.is_lowercase(),
        "latin" => is_latin && c.is_alphabetic(),
        "cyrillic" => matches!(u, 0x0400..=0x052F),
        "greek" => matches!(u, 0x0370..=0x03FF | 0x1F00..=0x1FFF),
        "arabic" => matches!(u, 0x0600..=0x06FF | 0x0750..=0x077F),
        "thai" => matches!(u, 0x0E00..=0x0E7F),
        "digit" => c.is_ascii_digit() || ('０'..='９').contains(&c),
        "punct" => matches!(
            c,
            '、' | '。' | '，' | '．' | '！' | '？' | '「' | '」' | '『' | '』' | '（' | '）' | '【' | '】'
                | '・' | '…' | 'ー' | '〜' | '～' | '：' | '；' | '!' | '?' | ',' | '.' | ':' | ';' | '(' | ')'
                | '[' | ']' | '{' | '}' | '-' | '—' | '"' | '\''
        ),
        _ => false,
    }
}

/// Parsed per-range declarations from `styles`, with `@class` composite rules expanded first
/// so explicit positional ranges (`start count ...`) always win when they overlap.
struct RangeStyle {
    start: usize,
    end: usize,
    decls: Vec<(String, String)>,
}

fn parse_decls(raw: &str) -> Vec<(String, String)> {
    let mut decls = Vec::new();
    for d in raw.split(';') {
        if let Some((k, v)) = d.trim().split_once(':') {
            let (k, v) = (k.trim(), v.trim());
            if !k.is_empty() && !v.is_empty() {
                decls.push((k.to_string(), v.to_string()));
            }
        }
    }
    decls
}

fn parse_range_styles(styles: &str, chars: &[char]) -> Vec<RangeStyle> {
    let n = chars.len();
    let mut class_ranges = Vec::new();
    let mut pos_ranges = Vec::new();
    for line in styles.lines() {
        let trimmed = line.trim();
        if let Some(rest) = trimmed.strip_prefix('@') {
            let mut it = rest.splitn(2, char::is_whitespace);
            let Some(cls) = it.next() else { continue };
            let decls = parse_decls(it.next().unwrap_or(""));
            if decls.is_empty() {
                continue;
            }
            let mut i = 0;
            while i < n {
                if !char_matches_class(chars[i], cls) {
                    i += 1;
                    continue;
                }
                let start = i;
                while i < n && char_matches_class(chars[i], cls) {
                    i += 1;
                }
                class_ranges.push(RangeStyle { start, end: i, decls: decls.clone() });
            }
            continue;
        }
        let mut it = trimmed.splitn(3, char::is_whitespace);
        let (Some(s_tok), Some(c_tok)) = (it.next(), it.next()) else { continue };
        let (Ok(start), Ok(count)) = (s_tok.parse::<usize>(), c_tok.parse::<usize>()) else { continue };
        let decls = parse_decls(it.next().unwrap_or(""));
        let s = start.min(n);
        let e = (start + count).min(n);
        if s < e && !decls.is_empty() {
            pos_ranges.push(RangeStyle { start: s, end: e, decls });
        }
    }
    class_ranges.extend(pos_ranges);
    class_ranges
}

/// The words as HTML: each run of characters that the same ranges cover, in a span with their declarations in order.
fn spans(words: &str, styles: &str, fallback: &str) -> String {
    let chars: Vec<char> = words.chars().collect();
    let n = chars.len();
    let ranges: Vec<(usize, usize, String)> = parse_range_styles(styles, &chars)
        .into_iter()
        .map(|r| {
            let css: Vec<String> = r
                .decls
                .into_iter()
                .map(|(k, v)| {
                    if k == "font-family" {
                        format!("{k}: {v}, {fallback}")
                    } else {
                        format!("{k}: {v}")
                    }
                })
                .collect();
            (r.start, r.end, css.join("; "))
        })
        .filter(|r| !r.2.is_empty())
        .collect();
    let mut cuts: Vec<usize> = ranges.iter().flat_map(|r| [r.0, r.1]).chain([0, n]).collect();
    cuts.sort_unstable();
    cuts.dedup();
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

/// Collects one glyph's outline, moved to where it is set, slanted or rotated 90° clockwise for Latin in vertical text.
struct Pen<'a> {
    verbs: &'a mut Vec<u8>,
    points: &'a mut Vec<f32>,
    at: (f32, f32),
    italic: f32,
    rotate_cw: bool,
    ink: (f32, f32),
}

impl Pen<'_> {
    fn map(&self, x: f32, y: f32) -> (f32, f32) {
        if self.rotate_cw {
            // Rotate glyph 90° clockwise around baseline origin (y-up -> screen y-down):
            // (x_up, y_up) -> screen (+y_up, +x_up)
            (self.at.0 + y, self.at.1 + x)
        } else {
            // skrifa's y goes up from the baseline; the page's goes down.
            (self.at.0 + x + self.italic * y, self.at.1 - y)
        }
    }

    fn put(&mut self, x: f32, y: f32) {
        let (px, py) = self.map(x, y);
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
        let n = self.points.len();
        let (sx, sy) = (self.points[n - 2], self.points[n - 1]);
        let (qx, qy) = self.map(cx, cy);
        let (ex, ey) = self.map(x, y);
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

fn parse_hex_color(s: &str) -> Option<[f32; 4]> {
    let hex = s.trim().strip_prefix('#')?;
    if hex.len() != 6 && hex.len() != 8 {
        return None;
    }
    let r = u8::from_str_radix(&hex[0..2], 16).ok()? as f32 / 255.0;
    let g = u8::from_str_radix(&hex[2..4], 16).ok()? as f32 / 255.0;
    let b = u8::from_str_radix(&hex[4..6], 16).ok()? as f32 / 255.0;
    let a = if hex.len() == 8 { u8::from_str_radix(&hex[6..8], 16).ok()? as f32 / 255.0 } else { 1.0 };
    Some([r, g, b, a])
}

fn parse_variations(css: &str) -> Vec<Variation> {
    let mut out = Vec::new();
    for part in css.split(',') {
        let mut it = part.trim().split_whitespace();
        let Some(tag_s) = it.next() else { continue };
        let Some(val_s) = it.next() else { continue };
        let clean = tag_s.trim_matches(['\'', '"']);
        if clean.len() == 4 && clean.is_ascii() {
            if let (Ok(tag), Ok(value)) = (HbTag::from_str(clean), val_s.parse::<f32>()) {
                out.push(Variation { tag, value });
            }
        }
    }
    out
}

/// True for characters that remain upright in vertical-rl Japanese typesetting.
fn is_upright_vertical(c: char) -> bool {
    let u = c as u32;
    matches!(
        u,
        0x3000..=0x30FF // CJK symbols, Hiragana, Katakana
            | 0x31F0..=0x31FF
            | 0x3200..=0x9FFF // CJK Unified Ideographs
            | 0xF900..=0xFAFF
            | 0xFE10..=0xFE1F
            | 0xFE30..=0xFE6F
            | 0xFF00..=0xFFEF // Fullwidth forms
            | 0x20000..=0x2FA1F
    ) || matches!(c, '…' | '‥' | '―' | '—' | '–' | '〜' | '～' | '・')
}

/// True when `font` has a `vert` or `vrt2` substitution for `c` (so HarfRust handles it upright).
fn has_vertical_glyph(face: &FontRef<'_>, c: char) -> bool {
    let Some(gid) = face.charmap().map(c) else { return false };
    let data = ShaperData::new(face);
    let shaper = data.shaper(face).build();
    let mut buf = UnicodeBuffer::new();
    let mut s = [0u8; 4];
    buf.push_str(c.encode_utf8(&mut s));
    buf.set_direction(Direction::TopToBottom);
    buf.set_script(harfrust::script::HAN);
    let feats = [
        Feature::new(HbTag::new(b"vert"), 1, ..),
        Feature::new(HbTag::new(b"vrt2"), 1, ..),
    ];
    let shaped = shaper.shape(buf, ShapeOptions::new().features(&feats));
    shaped.glyph_infos().first().is_some_and(|g| g.glyph_id != gid.to_u32())
}

/// True for ASCII/Latin letters & digits rotated 90° clockwise in vertical-rl text.
fn rotates_in_vertical(c: char) -> bool {
    c.is_ascii_alphanumeric() || matches!(c, ' ' | '-' | '_' | '/' | '.' | ',' | ':' | ';')
}

/// Vertical-rl Japanese typesetting using HarfRust (`Direction::TopToBottom` + OpenType
/// `vert`/`vrt2`/`vpal`/`vhal`) and Skrifa outlines/metrics, with kinsoku & hanging punctuation.
#[allow(clippy::too_many_arguments)]
fn set_vertical(words: &str, styles: &str, fonts: &[Vec<u8>], size: f32, line: f32, tracking: f32, slant: f32,
                wrap: f32, kinsoku: &str, hanging: bool, align: f32, features: &str) -> Option<Text> {
    let first = FontRef::new(fonts.first()?).ok()?;
    let m = first.metrics(Size::new(size), LocationRef::default());
    let chars: Vec<char> = words.chars().collect();
    let n = chars.len();
    let ranges = parse_range_styles(styles, &chars);

    // Load range fonts alongside the layer/fallback fonts.
    let mut font_bytes: Vec<Vec<u8>> = fonts.to_vec();
    let mut font_by_path: HashMap<String, usize> = HashMap::new();
    for path in range_fonts(styles) {
        if let Ok(b) = std::fs::read(&path) {
            let idx = font_bytes.len();
            font_bytes.push(b);
            font_by_path.insert(path, idx);
        }
    }

    let base_feats = parse_features(features);
    let strict_kinsoku = kinsoku.trim() == "strict";
    let no_kinsoku = matches!(kinsoku.trim(), "none" | "anywhere");
    let tracking_em = tracking / 1000.0;
    let slant_tan = slant.to_radians().tan();

    // Per-character resolved attributes.
    struct CharStyle {
        font_idx: usize,
        size: f32,
        tracking_px: f32,
        color: Option<[f32; 4]>,
        variations: Vec<Variation>,
    }
    let mut cstyles = Vec::with_capacity(n);
    for i in 0..n {
        let mut font_idx = 0usize;
        let mut sz = size;
        let mut tr = tracking_em * size;
        let mut color = None;
        let mut vars = Vec::new();
        for r in &ranges {
            if i < r.start || i >= r.end {
                continue;
            }
            for (k, v) in &r.decls {
                match k.as_str() {
                    "font-size" => {
                        if let Some(pct) = v.strip_suffix('%').and_then(|s| s.trim().parse::<f32>().ok()) {
                            sz = size * pct / 100.0;
                        } else if let Some(px) = v.strip_suffix("px").and_then(|s| s.trim().parse::<f32>().ok()) {
                            sz = px;
                        }
                    }
                    "letter-spacing" => {
                        if let Some(em) = v.strip_suffix("em").and_then(|s| s.trim().parse::<f32>().ok()) {
                            tr = em * sz;
                        }
                    }
                    "color" => {
                        if let Some(c) = parse_hex_color(v) {
                            color = Some(c);
                        }
                    }
                    "font-family" => {
                        if let Some(first_f) = v.split(',').next() {
                            let clean = first_f.trim().trim_matches(['\'', '"']);
                            if let Some(&idx) = font_by_path.get(clean) {
                                font_idx = idx;
                            }
                        }
                    }
                    "font-variation-settings" => {
                        vars = parse_variations(v);
                    }
                    _ => {}
                }
            }
        }
        // Fallback to a later font when the chosen font lacks this character.
        let ch = chars[i];
        if ch != '\n' && ch != '\r' {
            let has_in = |idx: usize| FontRef::new(&font_bytes[idx]).ok().and_then(|f| f.charmap().map(ch)).is_some();
            if !has_in(font_idx) {
                for alt in 0..font_bytes.len() {
                    if has_in(alt) {
                        font_idx = alt;
                        break;
                    }
                }
            }
        }
        cstyles.push(CharStyle { font_idx, size: sz, tracking_px: tr, color, variations: vars });
    }

    // Shape each character vertically with HarfRust to obtain glyph id, offsets, and advance.
    struct ShapedChar {
        idx: usize,
        font_idx: usize,
        glyph_id: u32,
        size: f32,
        advance_y: f32,
        x_offset: f32,
        y_offset: f32,
        rotate_cw: bool,
        color: Option<[f32; 4]>,
        coords: Vec<F2Dot14>,
    }

    let mut shaped_chars: Vec<Option<ShapedChar>> = Vec::with_capacity(n);
    for i in 0..n {
        let ch = chars[i];
        if ch == '\n' || ch == '\r' {
            shaped_chars.push(None);
            continue;
        }
        let cs = &cstyles[i];
        let Ok(face) = FontRef::new(&font_bytes[cs.font_idx]) else {
            shaped_chars.push(None);
            continue;
        };
        let upem = face.metrics(Size::new(cs.size), LocationRef::default()).units_per_em as f32;
        let scale = if upem > 0.0 { cs.size / upem } else { 1.0 };
        let inst = ShaperInstance::from_variations(&face, cs.variations.iter().copied());
        let coords: Vec<F2Dot14> = inst.coords().iter().map(|c| F2Dot14::from_bits(c.to_bits())).collect();
        let shaper_data = ShaperData::new(&face);
        let shaper = shaper_data.shaper(&face).instance(Some(&inst)).build();

        let rotate_cw = rotates_in_vertical(ch) && !is_upright_vertical(ch) && !has_vertical_glyph(&face, ch);
        let mut buf = UnicodeBuffer::new();
        let mut s_buf = [0u8; 4];
        buf.push_str(ch.encode_utf8(&mut s_buf));
        if rotate_cw {
            buf.set_direction(Direction::LeftToRight);
            buf.guess_segment_properties();
        } else {
            buf.set_direction(Direction::TopToBottom);
            buf.set_script(harfrust::script::HAN);
            if let Ok(lang) = Language::from_str("ja") {
                buf.set_language(lang);
            }
        }
        let mut feats = Vec::with_capacity(base_feats.len() + 2);
        if !rotate_cw {
            feats.push(Feature::new(HbTag::new(b"vert"), 1, ..));
            feats.push(Feature::new(HbTag::new(b"vrt2"), 1, ..));
        }
        for &(tag, val) in &base_feats {
            // Map horizontal CJK metrics tags to their vertical equivalents automatically.
            let mapped = if !rotate_cw {
                match &tag {
                    b"palt" => *b"vpal",
                    b"halt" => *b"vhal",
                    b"kern" => *b"vkrn",
                    b"pkna" => *b"vkna",
                    _ => tag,
                }
            } else {
                tag
            };
            feats.push(Feature::new(HbTag::new(&mapped), val, ..));
        }
        let out_buf = shaper.shape(buf, ShapeOptions::new().features(&feats));
        let Some(info) = out_buf.glyph_infos().first() else {
            shaped_chars.push(None);
            continue;
        };
        let pos = out_buf.glyph_positions()[0];
        let (adv_y, xo, yo) = if rotate_cw {
            (pos.x_advance as f32 * scale, -0.35 * cs.size, pos.y_offset as f32 * scale)
        } else {
            // In HarfRust TopToBottom, y_advance is negative (downward).
            let raw_adv = (-pos.y_advance as f32 * scale).max(0.0);
            let adv = if raw_adv > 1.0 { raw_adv } else { cs.size };
            (adv, pos.x_offset as f32 * scale, -pos.y_offset as f32 * scale)
        };
        shaped_chars.push(Some(ShapedChar {
            idx: i,
            font_idx: cs.font_idx,
            glyph_id: info.glyph_id,
            size: cs.size,
            advance_y: (adv_y + cs.tracking_px).max(0.0),
            x_offset: xo,
            y_offset: yo,
            rotate_cw,
            color: cs.color,
            coords,
        }));
    }

    // Partition into columns respecting `\n`, column wrap height, kinsoku, and hanging punctuation.
    let mut columns: Vec<Vec<usize>> = Vec::new();
    let mut col: Vec<usize> = Vec::new();
    let mut col_h = 0.0f32;
    let mut i = 0usize;
    while i < n {
        if chars[i] == '\r' {
            i += 1;
            continue;
        }
        if chars[i] == '\n' {
            columns.push(std::mem::take(&mut col));
            col_h = 0.0;
            i += 1;
            continue;
        }
        let adv = shaped_chars[i].as_ref().map_or(0.0, |s| s.advance_y);
        if wrap > 0.0 && !col.is_empty() && col_h + adv > wrap + 0.5 {
            // Hanging punctuation: allow one trailing punctuation mark past the column measure.
            if hanging && is_hanging_punct(chars[i]) {
                col.push(i);
                columns.push(std::mem::take(&mut col));
                col_h = 0.0;
                i += 1;
                continue;
            }
            // Kinsoku: pull previous character into next column if this char is line-start forbidden
            // or the previous char is line-end forbidden (opening bracket).
            if !no_kinsoku && (is_kinsoku_start(chars[i], strict_kinsoku) || col.last().is_some_and(|&p| is_kinsoku_end(chars[p]))) {
                if col.len() > 1 {
                    let moved = col.pop().unwrap();
                    columns.push(std::mem::take(&mut col));
                    col.push(moved);
                    col_h = shaped_chars[moved].as_ref().map_or(0.0, |s| s.advance_y);
                    continue;
                }
            }
            columns.push(std::mem::take(&mut col));
            col_h = 0.0;
        }
        col.push(i);
        col_h += adv;
        i += 1;
    }
    if !col.is_empty() || columns.is_empty() {
        columns.push(col);
    }

    let col_pitch = size * line.max(0.5);
    let num_cols = columns.len();
    let col_height = |c: &[usize]| -> f32 {
        let mut h = 0.0f32;
        for (pos, &idx) in c.iter().enumerate() {
            let is_last = pos + 1 == c.len();
            if hanging && is_last && is_hanging_punct(chars[idx]) {
                continue;
            }
            h += shaped_chars[idx].as_ref().map_or(0.0, |s| s.advance_y);
        }
        h
    };
    let tallest = columns.iter().map(|c| col_height(c)).fold(0.0f32, f32::max).max(size);

    let mut out = Text {
        verbs: Vec::new(),
        points: Vec::new(),
        lines: Vec::new(),
        letters: vec![[0.0; 5]; n],
        colors: Vec::new(),
        font: [m.ascent, -m.descent],
    };

    // Vertical-rl: column 0 sits at the rightmost x, progressing left by `col_pitch`.
    for (col_idx, col_chars) in columns.iter().enumerate() {
        let cx = (num_cols - 1 - col_idx) as f32 * col_pitch + 0.5 * size;
        let ch_total = col_height(col_chars);
        let mut y = align * (tallest - ch_total).max(0.0);
        for &idx in col_chars {
            let Some(sc) = shaped_chars[idx].as_ref() else { continue };
            let Ok(face) = FontRef::new(&font_bytes[sc.font_idx]) else { continue };
            let outlines = face.outline_glyphs();
            let gm = face.metrics(Size::new(sc.size), LocationRef::new(&sc.coords));
            let glyph_metrics = face.glyph_metrics(Size::new(sc.size), LocationRef::new(&sc.coords));
            let mut ink = (f32::INFINITY, f32::NEG_INFINITY);
            let (gx, gy) = if sc.rotate_cw {
                (cx + sc.x_offset, y + sc.y_offset)
            } else {
                // Center horizontal advance around column axis `cx`, placing baseline at y + ascent.
                let gw = glyph_metrics.advance_width(sc.glyph_id.into()).unwrap_or(sc.size);
                (cx - 0.5 * gw + sc.x_offset, y + gm.ascent + sc.y_offset)
            };
            if let Some(o) = outlines.get(sc.glyph_id.into()) {
                let mut pen = Pen {
                    verbs: &mut out.verbs,
                    points: &mut out.points,
                    at: (gx, gy),
                    italic: if sc.rotate_cw { 0.0 } else { slant_tan },
                    rotate_cw: sc.rotate_cw,
                    ink,
                };
                let _ = o.draw(DrawSettings::unhinted(Size::new(sc.size), LocationRef::new(&sc.coords)), &mut pen);
                ink = pen.ink;
            }
            let (a, b) = if ink.0 <= ink.1 { ink } else { (0.0, 0.0) };
            out.letters[sc.idx] = [cx - 0.5 * sc.size, sc.size, a, b, col_idx as f32];
            if let Some(c) = sc.color {
                out.colors.push([cx - 0.5 * sc.size, y, sc.size, sc.advance_y, c[0], c[1], c[2], c[3]]);
            }
            y += sc.advance_y;
        }
        out.lines.push([y, m.ascent, -m.descent, cx - 0.5 * size, size]);
    }
    Some(out)
}

#[allow(clippy::too_many_arguments)]
pub fn set(words: &str, styles: &str, fonts: &[Vec<u8>], size: f32, line: f32, tracking: f32, slant: f32,
           wrap: f32, break_all: bool, align: f32, vertical: bool, kinsoku: &str, hanging: bool,
           features: &str) -> Option<Text> {
    if vertical {
        return set_vertical(words, styles, fonts, size, line, tracking, slant, wrap, kinsoku, hanging, align, features);
    }
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
    let width = if wrap > 0.0 {
        format!("width: {wrap}px; white-space: pre-wrap;")
    } else {
        "width: max-content; white-space: pre;".into()
    };
    let breaks = if break_all { "word-break: break-all;" } else { "" };
    let lb = css_line_break(kinsoku);
    let feat_css = format_css_features(&parse_features(features));
    // Tracking in thousandths of an em, as After Effects' Character panel gives it.
    let tracking = tracking / 1000.0;
    // `lang="ja"` enables ICU4X Japanese kinsoku line-breaking and OpenType `locl` forms.
    let page = format!(
        r#"<html lang="ja"><body style="margin: 0"><div id="motolii-text" lang="ja" style="font-family: {}; font-size: {size}px; line-height: {line}; letter-spacing: {tracking}em; font-style: oblique {slant}deg; line-break: {lb}; color: {UNSET}; {width} {breaks} {feat_css}">{}</div></body></html>"#,
        families.join(", "),
        spans(words, styles, &families.join(", "))
    );
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
    let mut out = Text {
        verbs: Vec::new(),
        points: Vec::new(),
        lines: Vec::new(),
        letters: vec![[0.0; 5]; words.chars().count()],
        colors: Vec::new(),
        font: [m.ascent, -m.descent],
    };

    // Measure each line's visible advance (excluding one trailing hanging punctuation when enabled).
    let line_hang: Vec<f32> = laid
        .lines()
        .map(|l| {
            if !hanging {
                return 0.0;
            }
            let r = l.text_range();
            let slice = words.get(r.start..r.end).unwrap_or("").trim_end_matches(['\n', '\r']);
            let Some(last_ch) = slice.chars().last() else { return 0.0 };
            if !is_hanging_punct(last_ch) {
                return 0.0;
            }
            let last_byte = r.start + slice.len() - last_ch.len_utf8();
            for item in l.items() {
                if let PositionedLayoutItem::GlyphRun(g) = item {
                    for cl in g.run().visual_clusters() {
                        if cl.text_range().start == last_byte {
                            return cl.advance();
                        }
                    }
                }
            }
            0.0
        })
        .collect();

    let widest = laid
        .lines()
        .enumerate()
        .map(|(k, l)| (l.metrics().advance - line_hang[k]).max(0.0))
        .fold(0.0, f32::max);

    for (k, l) in laid.lines().enumerate() {
        let lm = l.metrics();
        let vis_adv = (lm.advance - line_hang[k]).max(0.0);
        let shift = align * (widest - vis_adv);
        let across = |x: f32| shift + x;
        let (mut up, mut down) = (0.0f32, 0.0f32);
        let mut read = HashMap::<usize, usize>::new();
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
            let italic = run.synthesis().skew().map_or(0.0, |a| a.to_radians().tan());
            let mut x = g.offset();
            let start = x;
            let from = read.entry(run.index()).or_insert(0);
            let clusters: Vec<_> =
                run.visual_clusters().skip(*from).take_while(|c| c.style_index() == g.style_index()).collect();
            *from += clusters.len();
            for cluster in clusters {
                let mut ink = (f32::INFINITY, f32::NEG_INFINITY);
                let mut gx = x;
                for glyph in cluster.glyphs() {
                    if let Some(o) = outlines.get(glyph.id.into()) {
                        let mut pen = Pen {
                            verbs: &mut out.verbs,
                            points: &mut out.points,
                            at: (across(gx + glyph.x), g.baseline() + glyph.y),
                            italic,
                            rotate_cw: false,
                            ink,
                        };
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
        out.lines.push([lm.baseline, up, down, across(0.0), vis_adv]);
    }
    Some(out)
}

/// Reads variable-font axes (`fvar`) and OpenType feature tags (`GSUB`/`GPOS`) from font bytes.
pub fn font_meta(bytes: &[u8]) -> Option<String> {
    let face = FontRef::from_index(bytes, 0).ok()?;
    let mut tags = BTreeSet::<Tag>::new();
    if let Ok(gsub) = face.gsub() && let Ok(list) = gsub.feature_list() {
        for rec in list.feature_records() {
            tags.insert(rec.feature_tag());
        }
    }
    if let Ok(gpos) = face.gpos() && let Ok(list) = gpos.feature_list() {
        for rec in list.feature_records() {
            tags.insert(rec.feature_tag());
        }
    }
    let mut out = String::from("features:");
    for t in &tags {
        out.push(' ');
        out.push_str(&t.to_string());
    }
    for axis in face.axes().iter() {
        if axis.is_hidden() {
            continue;
        }
        let name = face
            .localized_strings(axis.name_id())
            .english_or_first()
            .map(|s| s.to_string())
            .unwrap_or_else(|| axis.tag().to_string());
        out.push_str(&format!(
            "\naxis: {}\t{}\t{}\t{}\t{}",
            axis.tag(),
            axis.min_value(),
            axis.default_value(),
            axis.max_value(),
            name
        ));
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
                                          break_all: i32, align: f32, vertical: i32, kinsoku: *const c_char,
                                          hanging: i32, features: *const c_char) -> *mut Text {
    let (words, styles, fonts, kinsoku, features) =
        unsafe { (text(words), text(styles), text(fonts), text(kinsoku), text(features)) };
    let bytes: Vec<Vec<u8>> = fonts.lines().filter_map(|f| std::fs::read(f).ok()).collect();
    std::panic::catch_unwind(|| {
        set(
            words,
            styles,
            &bytes,
            size,
            line,
            tracking,
            slant,
            wrap,
            break_all != 0,
            align,
            vertical != 0,
            kinsoku,
            hanging != 0,
            features,
        )
    })
    .ok()
    .flatten()
    .map_or(std::ptr::null_mut(), |t| Box::into_raw(Box::new(t)))
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn motolii_font_meta_read(font_file: *const c_char, out: *mut c_char, cap: i32) -> i32 {
    let path = unsafe { text(font_file) };
    let Ok(bytes) = std::fs::read(path) else { return 0 };
    let Some(meta) = std::panic::catch_unwind(|| font_meta(&bytes)).ok().flatten() else { return 0 };
    let b = meta.as_bytes();
    if !out.is_null() && cap > 0 {
        let take = b.len().min((cap - 1) as usize);
        unsafe {
            std::ptr::copy_nonoverlapping(b.as_ptr(), out as *mut u8, take);
            *out.add(take) = 0;
        }
    }
    b.len() as i32
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
    use super::{font_meta, set};

    fn noto_jp() -> Vec<u8> {
        std::fs::read(concat!(env!("CARGO_MANIFEST_DIR"), "/../../third_party/noto_sans_jp/NotoSansJP-Regular.otf"))
            .unwrap()
    }

    #[test]
    fn a_range_sets_its_letters_larger_and_coloured() {
        let font = noto_jp();
        let t = set("ひらがな漢字と", "4 2 font-size: 150%; color: #ff8a3d", &[font], 100.0, 1.2, 0.0, 0.0, 0.0,
                    false, 0.0, false, "normal", false, "")
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

    #[test]
    fn a_range_sets_its_letters_in_a_font_file() {
        let jp = noto_jp();
        let roboto = concat!(env!("CARGO_MANIFEST_DIR"), "/../../third_party/filament_src/assets/fonts/Roboto-Medium.ttf");
        let plain = set("MMあ", "", std::slice::from_ref(&jp), 100.0, 1.2, 0.0, 0.0, 0.0, false, 0.0, false, "normal",
                        false, "")
            .unwrap();
        let t = set("MMあ", &format!("1 2 font-family: '{roboto}'"), &[jp], 100.0, 1.2, 0.0, 0.0, 0.0, false, 0.0,
                    false, "normal", false, "")
            .unwrap();
        let (a, b) = (&plain.letters, &t.letters);
        assert!((a[0][1] - b[0][1]).abs() < 0.5, "{a:?} {b:?}");
        assert!((a[1][1] - b[1][1]).abs() > 1.0, "{a:?} {b:?}");
        assert!(b[2][3] > b[2][2], "{b:?}");
    }

    #[test]
    fn proportional_metrics_tightens_japanese_punctuation() {
        let jp = noto_jp();
        let fixed = set("あ、い。「う」", "", std::slice::from_ref(&jp), 100.0, 1.2, 0.0, 0.0, 0.0, false, 0.0, false,
                        "normal", false, "")
            .unwrap();
        let palt = set("あ、い。「う」", "", std::slice::from_ref(&jp), 100.0, 1.2, 0.0, 0.0, 0.0, false, 0.0, false,
                       "normal", false, "palt kern")
            .unwrap();
        assert!(palt.lines[0][4] < fixed.lines[0][4] - 50.0, "fixed={} palt={}", fixed.lines[0][4], palt.lines[0][4]);
    }

    #[test]
    fn kinsoku_prevents_period_at_line_start() {
        let jp = noto_jp();
        // 3 chars wide (300px): "あいう。" with strict kinsoku must not leave "。" alone on line 2.
        let strict = set("あいう。", "", std::slice::from_ref(&jp), 100.0, 1.2, 0.0, 0.0, 300.0, false, 0.0, false,
                         "strict", false, "")
            .unwrap();
        // Line of 'う' (index 2) and '。' (index 3) must match (pushed together to line 2).
        assert_eq!(strict.letters[2][4], strict.letters[3][4], "{:?}", strict.letters);
    }

    #[test]
    fn hanging_punctuation_aligns_right_edge_without_period_width() {
        let jp = noto_jp();
        let no_hang = set("あいう\nあいう。", "", std::slice::from_ref(&jp), 100.0, 1.2, 0.0, 0.0, 0.0, false, 1.0,
                          false, "normal", false, "")
            .unwrap();
        let hang = set("あいう\nあいう。", "", std::slice::from_ref(&jp), 100.0, 1.2, 0.0, 0.0, 0.0, false, 1.0,
                       false, "normal", true, "")
            .unwrap();
        // Without hanging, line 1 shifts right by 100px to match "あいう。". With hanging, both lines start at x=0.
        assert!(no_hang.letters[0][0] > 50.0, "{:?}", no_hang.letters);
        assert!(hang.letters[0][0].abs() < 1.0, "{:?}", hang.letters);
    }

    #[test]
    fn vertical_typesetting_flows_top_to_bottom_and_right_to_left() {
        let jp = noto_jp();
        let t = set("あー。\nいう", "", std::slice::from_ref(&jp), 100.0, 1.2, 0.0, 0.0, 0.0, false, 0.0, true,
                    "strict", true, "")
            .unwrap();
        assert_eq!(t.lines.len(), 2, "{:?}", t.lines);
        // Column 0 ("あー。") lies to the right of column 1 ("いう") in vertical-rl.
        assert!(t.lines[0][3] > t.lines[1][3], "{:?}", t.lines);
        assert!(t.verbs.len() > 30);
    }

    #[test]
    fn font_meta_reads_opentype_features() {
        let jp = noto_jp();
        let meta = font_meta(&jp).unwrap();
        assert!(meta.contains("palt"), "{meta}");
        assert!(meta.contains("vert"), "{meta}");
    }

    #[test]
    fn class_rules_scale_hiragana_and_latin_case_while_explicit_range_wins() {
        let jp = noto_jp();
        // Kanji '漢' (100%), hiragana 'あ' (70%), uppercase 'A' (130%), lowercase 'a' (70%),
        // with explicit range overriding index 1 ('あ') to 150%.
        let styles = "@hiragana font-size: 70%\n@upper font-size: 130%\n@lower font-size: 70%\n1 1 font-size: 150%";
        let t = set("漢ああAa", styles, std::slice::from_ref(&jp), 100.0, 1.2, 0.0, 0.0, 0.0, false, 0.0, false,
                    "normal", false, "")
            .unwrap();
        // Index 0 ('漢') ~100px, index 1 ('あ' overridden) ~150px, index 2 ('あ' @hiragana) ~70px.
        assert!(t.letters[1][1] > t.letters[0][1] + 25.0, "{:?}", t.letters);
        assert!(t.letters[2][1] < t.letters[0][1] - 15.0, "{:?}", t.letters);
        // Uppercase 'A' (index 3) is wider than lowercase 'a' (index 4).
        assert!(t.letters[3][1] > t.letters[4][1] + 25.0, "{:?}", t.letters);
    }

    #[test]
    fn class_rules_apply_in_vertical_typesetting() {
        let jp = noto_jp();
        let plain = set("漢あ", "", std::slice::from_ref(&jp), 100.0, 1.2, 0.0, 0.0, 0.0, false, 0.0, true, "normal",
                        false, "")
            .unwrap();
        let scaled = set("漢あ", "@hiragana font-size: 75%", std::slice::from_ref(&jp), 100.0, 1.2, 0.0, 0.0, 0.0,
                         false, 0.0, true, "normal", false, "")
            .unwrap();
        // Column height shrinks when hiragana is scaled to 75%.
        assert!(scaled.lines[0][0] < plain.lines[0][0] - 10.0, "plain={} scaled={}", plain.lines[0][0],
                scaled.lines[0][0]);
    }

    #[test]
    fn hangul_and_script_classes_match_cleanly() {
        assert!(super::char_matches_class('한', "hangul"));
        assert!(super::char_matches_class('글', "hangul"));
        assert!(!super::char_matches_class('A', "hangul"));
        assert!(super::char_matches_class('А', "cyrillic"));
        assert!(!super::char_matches_class('А', "upper"));
        assert!(super::char_matches_class('A', "upper"));
        assert!(super::char_matches_class('Ω', "greek"));
        assert!(super::char_matches_class('ก', "thai"));
    }
}
