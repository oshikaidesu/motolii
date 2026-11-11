//! Animated SVG as posted (loaders such as github.com/n3r4zzurr0/svg-spinners, exports that move with CSS @keyframes).
//!
//! ThorVG draws SVG but runs no CSS animation. So Blitz (Stylo) plays the SVG's CSS, the SVG standing in an HTML page as
//! inline SVG does, and at each time the SVG is written again with what Stylo computes for each element put in its
//! attributes: ThorVG then draws a still SVG that is the frame. The posted text is kept as it is, values only replaced.
//! Checked against Chrome on the 46 CSS spinners: docs/design/next_expressions.md, Q9.

use std::ffi::{CStr, CString, c_char};

use blitz_dom::NodeId;
use style::properties::{ComputedValues, PropertyDeclarationId, PropertyId};

use crate::{Played, placed};

/// Properties every SVG element takes as a presentation attribute that Stylo computes and ThorVG reads (SVG2 §6.6,
/// svgwg.org/svg2-draft/styling.html#PresentationAttributes; ThorVG's loaders/svg/tvgSvgLoader.cpp, attribute tags).
const PAINT: [&str; 12] = ["opacity", "fill", "fill-opacity", "fill-rule", "stroke", "stroke-width", "stroke-opacity",
    "stroke-dasharray", "stroke-dashoffset", "stroke-linecap", "stroke-linejoin", "stroke-miterlimit"];
/// Elements whose paint is drawn or passed down (SVG2 §3.6, graphics and container elements, as ThorVG has them).
const DRAWN: [&str; 11] = ["svg", "g", "use", "circle", "ellipse", "rect", "line", "polyline", "polygon", "path", "text"];

/// Whether `attr` on a `tag` element is a presentation attribute (SVG2 §6.6, the table there): geometry only on the
/// elements it names, transform on all but patterns and gradients (they have their own), the rest on any SVG element.
fn presentation(attr: &str, tag: &str) -> bool {
    match attr {
        "cx" | "cy" => matches!(tag, "circle" | "ellipse"),
        "r" => tag == "circle",
        "rx" | "ry" => matches!(tag, "ellipse" | "rect"),
        "x" | "y" | "width" | "height" => matches!(tag, "foreignObject" | "image" | "rect" | "svg" | "symbol" | "use"),
        "transform" => !matches!(tag, "pattern" | "linearGradient" | "radialGradient"),
        a => PAINT.contains(&a),
    }
}

/// An attribute's value as CSS reads it. A bare number is a length in px where the property takes one (SVG2 §6.7); the
/// transform attribute has its own grammar (unitless, rotate about a point: css-transforms-1 §7.1), read by svgtypes,
/// resvg's, into the same functions in CSS's.
fn as_css(attr: &str, v: &str) -> String {
    use svgtypes::TransformListToken as T;
    match attr {
        "transform" => svgtypes::TransformListParser::from(v).map_while(Result::ok).map(|t| match t {
            T::Matrix { a, b, c, d, e, f } => format!("matrix({a},{b},{c},{d},{e},{f}) "),
            T::Translate { tx, ty } => format!("translate({tx}px,{ty}px) "),
            T::Scale { sx, sy } => format!("scale({sx},{sy}) "),
            T::Rotate { angle } => format!("rotate({angle}deg) "),
            T::SkewX { angle } => format!("skewX({angle}deg) "),
            T::SkewY { angle } => format!("skewY({angle}deg) "),
        }).collect(),
        "cx" | "cy" | "r" | "rx" | "ry" | "x" | "y" | "width" | "height" | "stroke-width" | "stroke-dashoffset"
            if v.trim().parse::<f64>().is_ok() => format!("{}px", v.trim()),
        _ => v.to_string(),
    }
}

/// One SVG element: where it is in the text, and what is written back into it.
struct Element {
    tag: String,
    /// The text offset just after the tag's name, where new attributes go.
    at: usize,
    /// The attributes' ranges in the text, by name.
    attrs: Vec<(String, std::ops::Range<usize>)>,
    node: Option<NodeId>,
}

pub struct Svg {
    text: String,
    played: Played,
    elements: Vec<Element>,
    /// The root's view box, x y w h: what transform-origin is measured against (transform-box view-box, the initial
    /// value, css-transforms-1 §5.2).
    view: [f32; 4],
}

impl Svg {
    pub fn new(text: &str) -> Option<Svg> {
        let doc = roxmltree::Document::parse(text).ok()?;
        let root = doc.root_element();
        let number = |a: &str| root.attribute(a).and_then(|v| v.trim_end_matches("px").parse::<f32>().ok());
        let view = root.attribute("viewBox").map(|v| {
            let n: Vec<f32> = v.split(|c: char| c == ',' || c.is_whitespace()).filter_map(|s| s.parse().ok()).collect();
            if n.len() == 4 { [n[0], n[1], n[2], n[3]] } else { [0.0; 4] }
        }).unwrap_or([0.0, 0.0, number("width").unwrap_or(300.0), number("height").unwrap_or(150.0)]);
        // Each element is marked, and its presentation attributes put, as :where() rules of specificity 0, in a style
        // sheet before the SVG's own (SVG2 §6.6): Blitz maps none of them. Before them, SVG's user agent rule for
        // transform-origin (SVG2 §6.12, svgwg.org/svg2-draft/styling.html#UAStyleSheet), also missing from Blitz.
        let (mut marked, mut rules, mut last) = (String::new(), String::from(":where(svg *){transform-origin:0 0}"), 0);
        let mut elements = Vec::new();
        for (k, n) in doc.descendants().filter(|n| n.is_element()).enumerate() {
            let start = n.range().start;
            let at = start + 1 + text[start + 1..].find(|c: char| c.is_whitespace() || c == '/' || c == '>').unwrap_or(0);
            marked += &text[last..at];
            marked += &format!(" data-motolii-n=\"{k}\"");
            last = at;
            let tag = n.tag_name().name().to_string();
            let decl: String = n.attributes().filter(|a| presentation(a.name(), &tag))
                .map(|a| format!("{}:{};", a.name(), as_css(a.name(), a.value()))).collect();
            if !decl.is_empty() { rules += &format!(":where([data-motolii-n=\"{k}\"]){{{decl}}}"); }
            let attrs = n.attributes().map(|a| (a.name().to_string(), a.range())).collect();
            elements.push(Element { tag, at, attrs, node: None });
        }
        marked += &text[last..];
        let page = format!("<!doctype html><html><head><meta charset=\"utf-8\"><style>{rules}</style></head><body>{marked}</body></html>");
        let size = (view[2].max(1.0) as u32, view[3].max(1.0) as u32);
        let played = Played::new(page, size);
        let nodes = played.doc.query_selector_all("[data-motolii-n]").ok()?.to_vec();
        if nodes.len() != elements.len() { return None; }
        for (e, n) in elements.iter_mut().zip(nodes) { e.node = Some(n); }
        Some(Svg { text: text.to_string(), played, elements, view })
    }

    /// The SVG as it is at `t` seconds.
    pub fn at(&mut self, t: f64) -> String {
        self.played.to(t);
        let doc = &self.played.doc;
        // (where in the text, how much of it goes, what comes in), applied from the end.
        let mut edits: Vec<(usize, usize, String)> = Vec::new();
        for (k, e) in self.elements.iter().enumerate() {
            let Some(styles) = e.node.and_then(|n| doc.get_node(n)).and_then(|n| n.primary_styles()) else { continue };
            if !DRAWN.contains(&e.tag.as_str()) { continue; }
            let mut written = Vec::new();
            for p in ["cx", "cy", "r", "rx", "ry", "x", "y", "width", "height"].into_iter().chain(PAINT) {
                if !presentation(p, &e.tag) || (k == 0 && matches!(p, "x" | "y" | "width" | "height")) { continue; }
                let v = value(&styles, p);
                // auto: not set, the element's own rule decides (rx, ry, a rect's size); a paint server stays as written.
                if v == "auto" || v.contains("url(") { continue; }
                written.push((p, v));
            }
            if k > 0 {
                let m = placed(&styles, &[self.view[0], self.view[1], self.view[0] + self.view[2], self.view[1] + self.view[3]]);
                written.push(("transform", format!("matrix({} {} {} {} {} {})", m.m11, m.m12, m.m21, m.m22, m.m41, m.m42)));
            }
            for (name, range) in &e.attrs {
                if written.iter().any(|(p, _)| p == name) { edits.push((range.start, range.len(), String::new())); }
            }
            let add: String = written.iter().map(|(p, v)| format!(" {p}=\"{v}\"")).collect();
            edits.push((e.at, 0, add));
        }
        edits.sort_by(|a, b| b.0.cmp(&a.0).then(b.1.cmp(&a.1)));
        let mut out = self.text.clone();
        for (at, len, s) in edits { out.replace_range(at..at + len, &s); }
        out
    }
}

/// A computed value as SVG writes it: lengths in user units, which are CSS px.
fn value(styles: &ComputedValues, property: &str) -> String {
    let Some(id) = PropertyId::parse_enabled_for_all_content(property).ok().and_then(|p| p.longhand_id()) else {
        return "auto".into();
    };
    let v = styles.computed_value_to_string(PropertyDeclarationId::Longhand(id));
    v.replace("px", "").replace('"', "'")
}

// The C side (svg.h). A panic inside Blitz or Stylo is caught here and the SVG treated as still.

pub struct MotoliiSvg {
    svg: Svg,
    out: CString,
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn motolii_svg_new(text: *const c_char) -> *mut MotoliiSvg {
    if text.is_null() { return std::ptr::null_mut(); }
    let text = unsafe { CStr::from_ptr(text) }.to_str().unwrap_or("");
    match std::panic::catch_unwind(|| Svg::new(text)) {
        Ok(Some(svg)) => Box::into_raw(Box::new(MotoliiSvg { svg, out: CString::default() })),
        _ => std::ptr::null_mut(),
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn motolii_svg_at(svg: *mut MotoliiSvg, t: f64) -> *const c_char {
    let Some(s) = (unsafe { svg.as_mut() }) else { return std::ptr::null() };
    let Ok(text) = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| s.svg.at(t))) else { return std::ptr::null() };
    s.out = CString::new(text).unwrap_or_default();
    s.out.as_ptr()
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn motolii_svg_free(svg: *mut MotoliiSvg) {
    if !svg.is_null() { drop(unsafe { Box::from_raw(svg) }); }
}
