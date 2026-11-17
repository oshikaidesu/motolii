// engine/community/css against Chrome, for where a pen's CSS lays the letters out (flex, grid).
// A case is cases/<name>.css, cases/<name>.html and chrome/<name>.json (measure.html run in Chrome): per [data-splitting]
// element its text, the advance of a space, and each letter's size and its box as Chrome lays it out.
// The letters are given to the page as Motolii gives them: in one row, each as wide as Chrome's letter, a space between
// words. Each letter's middle, moved by the matrix that comes back, is set beside Chrome's, both measured from the
// middle of all the letters (where the whole text stands is Motolii's to say, not the page's).
//   cargo run --release -- <cases dir> <chrome dir>
use motolii_css::Page;
use serde_json::Value;

fn main() {
    let a: Vec<String> = std::env::args().collect();
    let mut entries: Vec<_> = std::fs::read_dir(&a[2]).unwrap().map(|e| e.unwrap().path()).filter(|p| p.extension().is_some_and(|e| e == "json")).collect();
    entries.sort();
    let (mut all, mut off) = (0, 0);
    for path in entries {
        let stem = path.file_stem().unwrap().to_string_lossy().to_string();
        let read = |ext: &str| std::fs::read_to_string(format!("{}/{stem}.{ext}", a[1])).unwrap_or_default();
        // Every animation and transform stilled, as gen.py stills them for Chrome: only the layout is compared here.
        let (css, html) = (read("css") + "\n*,*::before,*::after{animation:none!important;transition:none!important;transform:none!important;translate:none!important;rotate:none!important;scale:none!important}", read("html"));
        let chrome: Value = serde_json::from_str(&std::fs::read_to_string(&path).unwrap()).unwrap();
        for (k, root) in chrome.as_array().unwrap().iter().enumerate() {
            let text = root["text"].as_str().unwrap();
            let (space, font) = (root["space"].as_f64().unwrap() as f32, root["font"].as_f64().unwrap() as f32);
            let got: Vec<Vec<f64>> = root["chars"].as_array().unwrap().iter().map(|c| c.as_array().unwrap().iter().map(|x| x.as_f64().unwrap()).collect()).collect();
            // Motolii's row: every character, spaces too.
            let (mut x, mut j) = (0.0f32, 0);
            let boxes: Vec<[f32; 4]> = text.chars().map(|c| {
                let (w, h) = if c.is_whitespace() { (space, got[0][1] as f32) } else { j += 1; (got[j - 1][0] as f32, got[j - 1][1] as f32) };
                x += w; [x - w + 100.0, 300.0, w, h]
            }).collect();
            let view = (root["view"][0].as_u64().unwrap() as u32, root["view"][1].as_u64().unwrap() as u32);
            let mut page = Page::new(&css, &html, text, k, false, view, font);
            let ours = page.at(0.0, &boxes);
            // Middles: ours (the given box's middle moved by the matrix), Chrome's (its laid-out box's).
            let (mut mine, mut theirs) = (Vec::new(), Vec::new());
            let mut j = 0;
            for (i, c) in text.chars().enumerate() {
                if c.is_whitespace() { continue; }
                let (m, b, g) = (&ours[i][1..], boxes[i], &got[j]); j += 1;
                mine.push(((b[0] + 0.5 * b[2]) as f64 + m[12], (b[1] + 0.5 * b[3]) as f64 + m[13], c));
                theirs.push((g[2] + 0.5 * g[4], g[3] + 0.5 * g[5]));
            }
            let mid = |v: &[(f64, f64)]| { let f = |k: usize, lo: bool| v.iter().map(|p| if k == 0 { p.0 } else { p.1 }).fold(if lo { f64::MAX } else { f64::MIN }, |a, b| if lo { a.min(b) } else { a.max(b) }); (0.5 * (f(0, true) + f(0, false)), 0.5 * (f(1, true) + f(1, false))) };
            // (The middle of the letters' boxes, not of their middles: the given sizes are the same on both sides.)
            let (cm, ct) = (mid(&mine.iter().map(|p| (p.0, p.1)).collect::<Vec<_>>()), mid(&theirs));
            let (mut worst, mut said) = (0.0f64, String::new());
            for (p, q) in mine.iter().zip(&theirs) {
                all += 1;
                let (dx, dy) = ((p.0 - cm.0) - (q.0 - ct.0), (p.1 - cm.1) - (q.1 - ct.1));
                let d = dx.abs().max(dy.abs());
                if d > 0.5 { off += 1; }
                if d >= worst { worst = d; said = format!("'{}' ours {:.2} {:.2}, chrome {:.2} {:.2}", p.2, p.0 - cm.0, p.1 - cm.1, q.0 - ct.0, q.1 - ct.1); }
            }
            if std::env::var("SHOW").is_ok_and(|n| n == stem) { for (p, q) in mine.iter().zip(&theirs) { println!("  '{}' ours {:8.2} {:8.2}   chrome {:8.2} {:8.2}", p.2, p.0 - cm.0, p.1 - cm.1, q.0 - ct.0, q.1 - ct.1); } }
            let spread = theirs.iter().map(|q| q.0).fold(f64::MIN, f64::max) - theirs.iter().map(|q| q.0).fold(f64::MAX, f64::min);
            let rows = { let mut ys: Vec<i64> = theirs.iter().map(|q| q.1.round() as i64).collect(); ys.sort(); ys.dedup(); ys.len() };
            println!("{stem} #{k} '{text}': worst {worst:.3} px ({said}); chrome's letters span {spread:.0} px across, {rows} row(s)");
        }
    }
    println!("{off} of {all} letters off by more than 0.5 px");
    if off > 0 || all == 0 { std::process::exit(1); }
}
