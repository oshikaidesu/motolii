//! Isolated worker process that loads and renders After Effects plugins (.plugin / .aex) via aexlo.
use aexlo::{Depth8, Host, Layer, ParamKind, ParamValue, PixelDepthKind, Time};
use std::fs::File;
use std::io::{self, BufReader, BufWriter, Read, Write};
use std::path::PathBuf;

// Duplicate stdout to a private FD and point stdout to stderr so plugin printf() calls cannot corrupt IPC.
#[cfg(unix)]
fn detach_protocol_stdout() -> File {
    use std::os::unix::io::FromRawFd;
    unsafe {
        let proto_fd = libc::dup(1);
        libc::dup2(2, 1);
        File::from_raw_fd(proto_fd)
    }
}

#[cfg(windows)]
fn detach_protocol_stdout() -> File {
    use std::os::windows::io::{FromRawHandle, RawHandle};
    unsafe extern "system" {
        fn GetStdHandle(n: u32) -> RawHandle;
        fn SetStdHandle(n: u32, h: RawHandle) -> i32;
    }
    const STD_OUTPUT_HANDLE: u32 = (-11i32) as u32;
    const STD_ERROR_HANDLE: u32 = (-12i32) as u32;
    unsafe {
        let out = GetStdHandle(STD_OUTPUT_HANDLE);
        let err = GetStdHandle(STD_ERROR_HANDLE);
        SetStdHandle(STD_OUTPUT_HANDLE, err);
        File::from_raw_handle(out)
    }
}

fn clean_field(s: &str) -> String {
    s.chars()
        .map(|c| match c {
            '\t' | '\r' | '\n' => ' ',
            _ => c,
        })
        .collect::<String>()
        .trim()
        .to_string()
}

fn run_probe(path: &PathBuf, out: &mut dyn Write) -> Result<(), Box<dyn std::error::Error>> {
    let mut fx = Host::get().load(path)?;
    let about = fx.about().unwrap_or_default();
    writeln!(out, "ABOUT\t{}", clean_field(&about))?;
    writeln!(
        out,
        "CAPS\t{}\t{}\t{}\t{}\t{}",
        u8::from(fx.supports_gpu()),
        u8::from(fx.supports_smart_render()),
        u8::from(fx.supports_depth(PixelDepthKind::U8)),
        u8::from(fx.supports_depth(PixelDepthKind::U16)),
        u8::from(fx.supports_depth(PixelDepthKind::F32)),
    )?;

    let count = fx.param_count();
    for i in 1..count {
        let Some(kind) = fx.param_kind(i) else {
            continue;
        };
        let label = clean_field(&fx.param_name(i).unwrap_or_default());
        match kind {
            ParamKind::GroupStart => {
                writeln!(out, "GROUP_START\t{i}\t{label}")?;
                continue;
            }
            ParamKind::GroupEnd => {
                writeln!(out, "GROUP_END\t{i}")?;
                continue;
            }
            _ => {}
        }
        if fx.param_hidden(i) {
            continue;
        }
        let val = fx.get_param(i);
        match kind {
            ParamKind::FloatSlider => {
                let (lo, hi) = fx.param_slider_range(i).unwrap_or((0.0, 100.0));
                let usual = match val {
                    Some(ParamValue::Float(v)) => v,
                    _ => lo,
                };
                writeln!(out, "PARAM\t{i}\tfloat\t{label}\t{lo}\t{hi}\t{usual}")?;
            }
            ParamKind::FixedSlider => {
                let (lo, hi) = fx.param_slider_range(i).unwrap_or((0.0, 100.0));
                let usual = match val {
                    Some(ParamValue::Fixed(v)) => v as f64,
                    _ => lo,
                };
                writeln!(out, "PARAM\t{i}\tfixed\t{label}\t{lo}\t{hi}\t{usual}")?;
            }
            ParamKind::Slider => {
                let (lo, hi) = fx.param_slider_range(i).unwrap_or((0.0, 100.0));
                let usual = match val {
                    Some(ParamValue::Slider(v)) => v as f64,
                    _ => lo,
                };
                writeln!(out, "PARAM\t{i}\tslider\t{label}\t{lo}\t{hi}\t{usual}")?;
            }
            ParamKind::Angle => {
                let usual = match val {
                    Some(ParamValue::Angle(v)) => v as f64,
                    _ => 0.0,
                };
                writeln!(out, "PARAM\t{i}\tangle\t{label}\t-360\t360\t{usual}")?;
            }
            ParamKind::Checkbox => {
                let usual = match val {
                    Some(ParamValue::Checkbox(b)) => u8::from(b),
                    _ => 0,
                };
                writeln!(out, "PARAM\t{i}\tcheck\t{label}\t0\t1\t{usual}")?;
            }
            ParamKind::Popup => {
                let choices: Vec<String> = fx
                    .param_choices(i)
                    .unwrap_or_default()
                    .into_iter()
                    .map(|c| clean_field(&c).replace('|', "/"))
                    .collect();
                let n = choices.len().max(1);
                let usual = match val {
                    Some(ParamValue::Popup(v)) => v.clamp(1, n as i32),
                    _ => 1,
                };
                writeln!(
                    out,
                    "PARAM\t{i}\tpopup\t{label}\t1\t{n}\t{usual}\t{}",
                    choices.join("|")
                )?;
            }
            ParamKind::Point => {
                let (iw, ih) = fx.input_size();
                let (w, h) = (iw.max(1) as f64, ih.max(1) as f64);
                let (x, y) = match val {
                    Some(ParamValue::Point { x, y }) => (x as f64 / w, y as f64 / h),
                    _ => (0.5, 0.5),
                };
                writeln!(out, "PARAM\t{i}\tpoint\t{label}\t{x}\t{y}")?;
            }
            ParamKind::Point3D => {
                let (iw, ih) = fx.input_size();
                let (w, h) = (iw.max(1) as f64, ih.max(1) as f64);
                let (x, y, z) = match val {
                    Some(ParamValue::Point3D { x, y, z }) => (x / w, y / h, z),
                    _ => (0.5, 0.5, 0.0),
                };
                writeln!(out, "PARAM\t{i}\tpoint3d\t{label}\t{x}\t{y}\t{z}")?;
            }
            ParamKind::Color => {
                let (r, g, b, a) = match val {
                    Some(ParamValue::Color {
                        red,
                        green,
                        blue,
                        alpha,
                    }) => (red, green, blue, alpha),
                    _ => (255, 255, 255, 255),
                };
                writeln!(out, "PARAM\t{i}\tcolor\t{label}\t{r}\t{g}\t{b}\t{a}")?;
            }
            ParamKind::Layer => {
                writeln!(out, "PARAM\t{i}\tlayer\t{label}")?;
            }
            _ => {}
        }
    }
    out.flush()?;
    Ok(())
}

fn read_u8(r: &mut impl Read) -> io::Result<u8> {
    let mut b = [0u8; 1];
    r.read_exact(&mut b)?;
    Ok(b[0])
}
fn read_u32(r: &mut impl Read) -> io::Result<u32> {
    let mut b = [0u8; 4];
    r.read_exact(&mut b)?;
    Ok(u32::from_le_bytes(b))
}
fn read_i32(r: &mut impl Read) -> io::Result<i32> {
    let mut b = [0u8; 4];
    r.read_exact(&mut b)?;
    Ok(i32::from_le_bytes(b))
}
fn read_f64(r: &mut impl Read) -> io::Result<f64> {
    let mut b = [0u8; 8];
    r.read_exact(&mut b)?;
    Ok(f64::from_le_bytes(b))
}

fn run_serve(path: &PathBuf, out_file: File) -> Result<(), Box<dyn std::error::Error>> {
    let mut fx = Host::get().load(path)?;
    let mut out = BufWriter::new(out_file);
    let mut inp = BufReader::new(io::stdin());
    out.write_all(b"AEW1")?;
    out.flush()?;

    let mut in_buf: Vec<u8> = Vec::new();
    let mut out_buf: Vec<u8> = Vec::new();
    let mut layer_buf: Vec<u8> = Vec::new();

    loop {
        let mut head = [0u8; 4];
        match inp.read_exact(&mut head) {
            Ok(()) => {}
            Err(e) if e.kind() == io::ErrorKind::UnexpectedEof => break,
            Err(e) => return Err(e.into()),
        }
        let w = u32::from_le_bytes(head);
        let h = read_u32(&mut inp)?;
        let time_sec = read_f64(&mut inp)?;
        let fps = read_f64(&mut inp)?;
        let param_count = read_u32(&mut inp)?;

        for _ in 0..param_count {
            let idx = read_u32(&mut inp)? as usize;
            let tag = read_u8(&mut inp)?;
            match tag {
                0 => {
                    let v = read_f64(&mut inp)?;
                    let _ = fx.set_param(idx, ParamValue::Float(v));
                }
                1 => {
                    let v = read_f64(&mut inp)?;
                    let _ = fx.set_param(idx, ParamValue::Fixed(v as f32));
                }
                2 => {
                    let v = read_i32(&mut inp)?;
                    let _ = fx.set_param(idx, ParamValue::Slider(v));
                }
                3 => {
                    let v = read_f64(&mut inp)?;
                    let _ = fx.set_param(idx, ParamValue::Angle(v as f32));
                }
                4 => {
                    let v = read_u8(&mut inp)?;
                    let _ = fx.set_param(idx, ParamValue::Checkbox(v != 0));
                }
                5 => {
                    let v = read_i32(&mut inp)?;
                    let _ = fx.set_param(idx, ParamValue::Popup(v));
                }
                6 => {
                    let x = read_f64(&mut inp)?;
                    let y = read_f64(&mut inp)?;
                    let _ = fx.set_param(idx, ParamValue::Point { x: x as f32, y: y as f32 });
                }
                7 => {
                    let x = read_f64(&mut inp)?;
                    let y = read_f64(&mut inp)?;
                    let z = read_f64(&mut inp)?;
                    let _ = fx.set_param(idx, ParamValue::Point3D { x, y, z });
                }
                8 => {
                    let r = read_u8(&mut inp)?;
                    let g = read_u8(&mut inp)?;
                    let b = read_u8(&mut inp)?;
                    let a = read_u8(&mut inp)?;
                    let _ = fx.set_param(
                        idx,
                        ParamValue::Color {
                            red: r,
                            green: g,
                            blue: b,
                            alpha: a,
                        },
                    );
                }
                9 => {
                    let lw = read_u32(&mut inp)?;
                    let lh = read_u32(&mut inp)?;
                    if lw == 0 || lh == 0 {
                        let _ = fx.clear_layer_param(idx);
                    } else {
                        let n = (lw as usize) * (lh as usize) * 4;
                        layer_buf.resize(n, 0);
                        inp.read_exact(&mut layer_buf)?;
                        if let Ok(layer) = Layer::<Depth8>::from_rgba8(layer_buf.clone(), lw, lh) {
                            let _ = fx.set_layer_param(idx, Some(layer));
                        }
                    }
                }
                _ => {}
            }
        }

        let in_bytes = (w as usize) * (h as usize) * 4;
        in_buf.resize(in_bytes, 0);
        inp.read_exact(&mut in_buf)?;

        let rate = if fps.is_finite() && fps > 0.0 {
            fps.round().clamp(1.0, 240.0) as u32
        } else {
            60
        };
        let frame = (time_sec.max(0.0) * rate as f64).round().clamp(0.0, i32::MAX as f64) as i32;
        fx.set_render_size(w, h);
        fx.set_time(Time::frame(frame, rate));

        let render_res = Layer::<Depth8>::from_rgba8(in_buf.clone(), w, h)
            .map_err(|e| e.to_string())
            .and_then(|layer| {
                fx.set_input_layer(layer);
                fx.render_frame().map_err(|e| e.to_string())
            });

        match render_res {
            Ok(()) => {
                let (ow, oh) = fx.output_size();
                let out_bytes = (ow as usize) * (oh as usize) * 4;
                out_buf.resize(out_bytes, 0);
                if let Err(e) = fx.write_output_rgba8(&mut out_buf) {
                    let msg = e.to_string();
                    out.write_all(&1u32.to_le_bytes())?;
                    out.write_all(&(msg.len() as u32).to_le_bytes())?;
                    out.write_all(msg.as_bytes())?;
                } else {
                    out.write_all(&0u32.to_le_bytes())?;
                    out.write_all(&ow.to_le_bytes())?;
                    out.write_all(&oh.to_le_bytes())?;
                    out.write_all(&out_buf)?;
                }
            }
            Err(msg) => {
                out.write_all(&1u32.to_le_bytes())?;
                out.write_all(&(msg.len() as u32).to_le_bytes())?;
                out.write_all(msg.as_bytes())?;
            }
        }
        out.flush()?;
    }
    Ok(())
}

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    if args.len() != 2 {
        eprintln!("Usage: motolii_ae_worker (--probe|--serve) <plugin>");
        std::process::exit(2);
    }
    let proto_out = detach_protocol_stdout();
    let path = PathBuf::from(&args[1]);
    let res = match args[0].as_str() {
        "--probe" => {
            let mut out = BufWriter::new(proto_out);
            run_probe(&path, &mut out)
        }
        "--serve" => run_serve(&path, proto_out),
        _ => {
            eprintln!("Unknown mode: {}", args[0]);
            std::process::exit(2);
        }
    };
    if let Err(e) = res {
        eprintln!("motolii_ae_worker error: {e}");
        std::process::exit(1);
    }
}
