// engine/community/css/svg.rs on svg-spinners: each spinner written at the times measure.js reads Chrome at.
//   svg_anim_probe <svg dir> <out dir>
fn main() {
    let a: Vec<String> = std::env::args().collect();
    let mut names: Vec<_> = std::fs::read_dir(&a[1]).unwrap().map(|e| e.unwrap().file_name().into_string().unwrap()).collect();
    names.sort();
    for n in names.iter().filter(|n| n.ends_with(".svg")) {
        let text = std::fs::read_to_string(format!("{}/{n}", a[1])).unwrap();
        let Some(mut svg) = motolii_css::svg::Svg::new(&text) else { println!("{n}: not read"); continue };
        for t in [0.3, 0.9, 1.7] {
            std::fs::write(format!("{}/{}@{t}.svg", a[2], n.trim_end_matches(".svg")), svg.at(t)).unwrap();
        }
    }
}
