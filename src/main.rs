use arrayvec::ArrayString;
use clap::{ArgAction, Parser};
use std::io::{BufWriter, StdoutLock, Write};

#[derive(Parser, Debug)]
#[command(author, version, about)]
struct Arguments {
    /// Add a keyword to the list
    #[arg(short, long, action = ArgAction::Append, required = true)]
    keyword: Vec<String>,

    /// Calculate how many passwords there will be
    #[arg(short, long, required = false)]
    calculate_size: bool,
}

fn generate(
    stdout_bufwriter: &mut BufWriter<StdoutLock>,
    keywords: &Vec<&str>,
    level: usize,
    prefix: &mut ArrayString<256>,
) {
    if level == 0 {
        stdout_bufwriter.write_all(prefix.as_bytes()).unwrap();
        stdout_bufwriter.write_all(b"\n").unwrap();
    } else {
        for item in keywords {
            let previous_length = prefix.len();
            prefix.push_str(item);
            generate(stdout_bufwriter, keywords, level - 1, prefix);
            prefix.truncate(previous_length);
        }
    }
}

fn calculate_combinations(n: u128, i: u32) -> u128 {
    if i == 1 {
        return n.into();
    } else {
        n.pow(i) + calculate_combinations(n, i - 1)
    }
}

fn main() {
    let arguments = Arguments::parse();
    let keywords: Vec<&str> = arguments.keyword.iter().map(|item| item.as_str()).collect();

    if arguments.calculate_size {
        let lines = calculate_combinations(keywords.len() as u128, keywords.len() as u32) + 1;
        let average_length =
            keywords.iter().map(|item| item.len()).sum::<usize>() as f64 / keywords.len() as f64;
        let mut estimated_bytes = 1.0;
        for i in 1..=keywords.len() {
            let current_lines = keywords.len().pow(i as u32) as f64;
            estimated_bytes += current_lines + current_lines * (average_length * i as f64)
        }
        println!(
            "keywords: {}\n\nline count: {}\nestimated bytes: {}",
            keywords.len(),
            lines,
            estimated_bytes,
        );
        return;
    }

    let mut stdout_bufwriter = BufWriter::new(std::io::stdout().lock());
    let mut prefix = ArrayString::<256>::new();
    for i in 0..=keywords.len() {
        generate(&mut stdout_bufwriter, &keywords, i, &mut prefix)
    }
}
