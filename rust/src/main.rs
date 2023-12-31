use arrayvec::ArrayString;
use clap::{ArgAction, Parser};
use std::io::{BufWriter, StdoutLock, Write};

const STRING_SIZE: usize = 512;

#[derive(Parser, Debug)]
#[command(version)]
struct Arguments {
    /// Add a keyword to the list
    #[arg(action = ArgAction::Append, required = true)]
    keyword: Vec<String>,

    /// Calculate output sizes
    #[arg(short, long, required = false)]
    calculate_size: bool,
}

fn generate(
    stdout_bufwriter: &mut BufWriter<StdoutLock>,
    keywords: &[&str],
    level: usize,
    prefix: &mut ArrayString<STRING_SIZE>,
) {
    if level == 0 {
        stdout_bufwriter.write_all(prefix.as_bytes()).unwrap();
        stdout_bufwriter.write_all(b"\n").unwrap();
    } else {
        let previous_length = prefix.len();
        for item in keywords {
            prefix.push_str(item);
            generate(stdout_bufwriter, keywords, level - 1, prefix);
            prefix.truncate(previous_length);
        }
    }
}

fn calculate_combinations(n: u128, i: u32) -> u128 {
    if i == 1 {
        n
    } else {
        n.pow(i) + calculate_combinations(n, i - 1)
    }
}

fn main() {
    let arguments = Arguments::parse();
    let keywords: Vec<&str> = arguments
        .keyword
        .iter()
        .map(std::string::String::as_str)
        .collect();

    if arguments.calculate_size {
        let lines =
            calculate_combinations(keywords.len() as u128, keywords.len().try_into().unwrap()) + 1;
        let average_length =
            keywords.iter().map(|item| item.len()).sum::<usize>() as f64 / keywords.len() as f64;
        let mut bytes = 1.0;
        for i in 1..=keywords.len() {
            let current_lines = keywords.len().pow(i.try_into().unwrap()) as f64;
            bytes += current_lines + current_lines * (average_length * i as f64);
        }
        println!(
            "keywords: {}\n\nlines: {lines}\nbytes: {bytes}",
            keywords.len(),
        );
        return;
    }

    let mut stdout_bufwriter = BufWriter::new(std::io::stdout().lock());
    let mut prefix = ArrayString::<STRING_SIZE>::new();
    for i in 0..=keywords.len() {
        generate(&mut stdout_bufwriter, &keywords, i, &mut prefix);
    }
}
