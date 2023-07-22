use std::io::{BufWriter, StdoutLock, Write};

const ITEMS: &[&str] = &["a", "b", "c", "d", "e", "f", "g", "h"];

fn generate(stdout_bufwriter: &mut BufWriter<StdoutLock>, level: usize, prefix: &mut String) {
    if level == 0 {
        stdout_bufwriter.write(prefix.as_bytes()).unwrap();
        stdout_bufwriter.write(b"\n").unwrap();
    } else {
        for &item in ITEMS {
            let previous_len = prefix.len();
            prefix.push_str(item);
            generate(stdout_bufwriter, level - 1, prefix);
            prefix.truncate(previous_len);
        }
    }
}

fn main() {
    let mut stdout_bufwriter = BufWriter::new(std::io::stdout().lock());
    let mut prefix = String::with_capacity(256);
    for i in 0..=ITEMS.len() {
        generate(&mut stdout_bufwriter, i, &mut prefix)
    }
}
