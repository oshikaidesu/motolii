// For each page: Blitz (Stylo) resolves the page at the given times, from 0 forward. For each .word and .char it writes
// its opacity and its transform as Stylo computes it, made a matrix by Stylo's own to_transform_3d_matrix_f64 against
// a box of 0 x 0, 1 x 0 and 0 x 1. A percentage moves the translation in proportion to the box, so the matrix for any
// box is M0 + w (Mw - M0) + h (Mh - M0): whoever draws the letter gives its own box. Written into the page as JSON (id
// "blitz") for Chrome to compare with its own values.
use blitz_dom::DocumentConfig;
use blitz_html::HtmlDocument;
use blitz_traits::shell::{ColorScheme, Viewport};
use euclid::default::{Point2D, Rect, Size2D};
use style::values::animated::{Animate, Procedure};
use style::values::computed::CSSPixelLength;
use style::values::computed::transform::{Matrix3D, Transform, TransformOperation};

// A computed transform made a matrix against the drawer's box. An InterpolateMatrix (keyframes that list different
// functions) is resolved as Stylo's own TODO says (values/generics/transform.rs, to_3d_matrix): each list made a matrix
// by the box, the two interpolated by Stylo's Matrix3D::animate (decomposition, values/animated/transform.rs). Then the
// list is multiplied by Stylo's own to_transform_3d_matrix_f64.
fn matrix(list: &Transform, r: &Rect<CSSPixelLength>) -> [f64; 16] {
    let ops: Vec<TransformOperation> = list.0.iter().map(|op| match op {
        TransformOperation::InterpolateMatrix { from_list, to_list, progress } => {
            let m = |l: &Transform| { let a = matrix(l, r); Matrix3D::from(euclid::default::Transform3D::from_array(a.map(|v| v as f32))) };
            let (a, b) = (m(from_list), m(to_list));
            TransformOperation::Matrix3D(a.animate(&b, Procedure::Interpolate { progress: progress.0 as f64 }).unwrap_or(a))
        }
        other => other.clone(),
    }).collect();
    style::values::generics::transform::GenericTransform(ops.into()).to_transform_3d_matrix_f64(Some(r)).map(|(m, _)| m.to_array()).unwrap_or([f64::NAN; 16])
}

fn main() {
    let a: Vec<String> = std::env::args().collect();
    let (from, to, times): (&str, &str, Vec<f64>) = (&a[1], &a[2], a[3].split(',').map(|x| x.parse().unwrap()).collect());
    for e in std::fs::read_dir(from).unwrap() {
        let path = e.unwrap().path();
        let page = std::fs::read_to_string(&path).unwrap();
        let config = DocumentConfig { viewport: Some(Viewport::new(1280, 720, 1.0, ColorScheme::Light)), ..Default::default() };
        let mut doc = HtmlDocument::from_html(&page, config);
        doc.resolve(0.0);
        let els = doc.query_selector_all(".word, .char").unwrap();
        // Each element's box, as the drawer gives it (for the check, Chrome's: boxes/<page>.json, [w, h] in order).
        let stem = path.file_stem().unwrap().to_string_lossy().to_string();
        let Ok(said) = std::fs::read_to_string(std::path::Path::new(&a[4]).join(format!("{stem}.json"))) else { continue };
        let boxes: Vec<(f32, f32)> = said.trim().trim_matches(|c| c == '[' || c == ']').split("],[").map(|p| { let mut v = p.split(',').map(|x| x.parse::<f32>().unwrap()); (v.next().unwrap(), v.next().unwrap()) }).collect();
        if let Ok(probe) = std::env::var("WATCH") {
            let ids: Vec<usize> = probe.split(',').map(|x| x.parse().unwrap()).collect();
            for f in 0..=24 {
                let t = f as f64 / 60.0; if f > 0 { doc.resolve(t); }
                if f % 4 == 0 { println!("t={t:.3} {}", ids.iter().map(|&k| doc.resolved_style_value(els[k], "transform")).collect::<Vec<_>>().join(" | ")); }
            }
            return;
        }
        let mut json = String::from("{");
        // Stylo moves an animation on by at most one iteration an update (iterate_if_necessary, servo/animation.rs), as
        // Servo updates once a frame: so the document is moved on a frame (1/60 s) at a time, as Motolii plays.
        let mut now = 0.0;
        for (k, &t) in times.iter().enumerate() {
            while now + 1.0 / 60.0 < t { now += 1.0 / 60.0; doc.resolve(now); }
            now = t;
            doc.resolve(t);
            let vals: Vec<String> = els.iter().enumerate().map(|(k, &id)| {
                let Some(styles) = doc.get_node(id).and_then(|n| n.primary_styles()) else { return "null".into() };
                let opacity = styles.get_effects().opacity;
                let (w, h) = boxes[k];
                let r = Rect::new(Point2D::new(CSSPixelLength::new(0.), CSSPixelLength::new(0.)), Size2D::new(CSSPixelLength::new(w), CSSPixelLength::new(h)));
                let m = matrix(&styles.get_box().transform, &r);
                format!("[{opacity},[{}]]", m.iter().map(|x| format!("{x}")).collect::<Vec<_>>().join(","))
            }).collect();
            json += &format!("{}\"{}\":[{}]", if k > 0 { "," } else { "" }, t, vals.join(","));
        }
        json += "}";
        let out = page.replacen("</head>", &format!("<script type=\"application/json\" id=\"blitz\">{json}</script></head>"), 1);
        std::fs::write(std::path::Path::new(to).join(path.file_name().unwrap()), out).unwrap();
        println!("{} {} elements", path.file_name().unwrap().to_string_lossy(), els.len());
    }
}

