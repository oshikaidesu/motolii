// engine/community/css against Chrome: for each pen and [data-splitting] element, the letters' boxes as Chrome lays them
// out with no transform are given; each letter's box moved by the matrix we return is set beside the box Chrome draws
// (getBoundingClientRect, measure.js), and our opacity beside Chrome's (its own times its ancestors').
//   cargo run --release -- <pens.json> <chrome dir>
use motolii_css::Page;
use serde_json::Value;

fn text_of(html: &str, nth: usize) -> String {
    let at = html.match_indices("data-splitting").nth(nth).unwrap().0;
    let open = at + html[at..].find('>').unwrap() + 1;
    html[open..open + html[open..].find('<').unwrap()].to_string()
}

fn main() {
    let a: Vec<String> = std::env::args().collect();
    let pens: Value = serde_json::from_str(&std::fs::read_to_string(&a[1]).unwrap()).unwrap();
    let mut entries: Vec<_> = std::fs::read_dir(&a[2]).unwrap().map(|e| e.unwrap().path()).collect();
    entries.sort();
    let (mut all, mut off) = (0, 0);
    for path in entries {
        let stem = path.file_stem().unwrap().to_string_lossy().to_string();
        let chrome: Value = serde_json::from_str(&std::fs::read_to_string(&path).unwrap()).unwrap();
        let (html, css) = (pens[format!("{stem}.html")].as_str().unwrap(), pens[format!("{stem}.css")].as_str().unwrap());
        let mut times: Vec<(f64, &Value)> = chrome.as_object().unwrap().iter().map(|(t, v)| (t.parse().unwrap(), v)).collect();
        times.sort_by(|x, y| x.0.partial_cmp(&y.0).unwrap());
        let roots = times[0].1.as_array().unwrap().len();
        for k in 0..roots {
            let text = text_of(html, k);
            let mut page = Page::new(css, html, &text, k, false, (1280, 720));
            let (mut worst, mut where_) = (0.0f64, String::new());
            for (t, v) in &times {
                let got: Vec<Vec<f64>> = v[k].as_array().unwrap().iter().map(|c| c.as_array().unwrap().iter().map(|x| x.as_f64().unwrap()).collect()).collect();
                let mut j = 0;
                let boxes: Vec<[f32; 4]> = text.chars().map(|c| if c.is_whitespace() { [0.0; 4] } else { j += 1; let g = &got[j - 1]; [g[0] as f32, g[1] as f32, g[2] as f32, g[3] as f32] }).collect();
                let ours = page.at(*t, &boxes);
                let mut j = 0;
                for (i, c) in text.chars().enumerate() {
                    if c.is_whitespace() { continue; }
                    let g = &got[j]; j += 1; all += 1;
                    let m = &ours[i][1..];
                    let (cx, cy) = (g[0] + g[2] / 2.0, g[1] + g[3] / 2.0);
                    let (mut x0, mut y0, mut x1, mut y1) = (f64::MAX, f64::MAX, f64::MIN, f64::MIN);
                    for (px, py) in [(g[0], g[1]), (g[0] + g[2], g[1]), (g[0], g[1] + g[3]), (g[0] + g[2], g[1] + g[3])] {
                        let (x, y) = (px - cx, py - cy);
                        let w = m[3] * x + m[7] * y + m[15];
                        let (qx, qy) = ((m[0] * x + m[4] * y + m[12]) / w + cx, (m[1] * x + m[5] * y + m[13]) / w + cy);
                        x0 = x0.min(qx); y0 = y0.min(qy); x1 = x1.max(qx); y1 = y1.max(qy);
                    }
                    let d = [(x0 - g[4]).abs(), (y0 - g[5]).abs(), (x1 - g[4] - g[6]).abs(), (y1 - g[5] - g[7]).abs()].into_iter().fold(0.0, f64::max);
                    let o = (ours[i][0] - g[8]).abs();
                    if d > 0.5 || o > 0.01 { off += 1; }
                    if d.max(o * 100.0) > worst { worst = d.max(o * 100.0); where_ = format!("t={t} '{c}' #{i}: ours [{x0:.2} {y0:.2} {x1:.2} {y1:.2}] op {:.3}, chrome [{:.2} {:.2} {:.2} {:.2}] op {:.3}", ours[i][0], g[4], g[5], g[4] + g[6], g[5] + g[7], g[8]); }
                }
            }
            println!("{stem} #{k} '{text}': worst {worst:.3} {where_}");
        }
    }
    println!("{} of {all} letter-times off (box > 0.5 px or opacity > 0.01)", off);
}
