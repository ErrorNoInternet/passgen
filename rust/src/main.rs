#![warn(clippy::pedantic)]

use clap::{ArgAction, Parser};
use std::{
    fs::File,
    io::{BufWriter, Write},
    os::fd::FromRawFd,
};

const STRING_SIZE: usize = 512;

#[derive(Parser, Debug)]
#[command(version)]
struct Arguments {
    /// Add a keyword to the list
    #[arg(action = ArgAction::Append, required = true)]
    keyword: Vec<String>,

    /// Calculate output sizes
    #[arg(short, long)]
    calculate_size: bool,
}

fn generate(
    stdout_bufwriter: &mut BufWriter<File>,
    keywords: &[&[u8]],
    prefix: &mut [u8; STRING_SIZE],
    prefix_len: usize,
    level: usize,
) {
    if level == 0 {
        prefix[prefix_len] = b'\n';
        unsafe {
            stdout_bufwriter
                .write_all(&prefix[..=prefix_len])
                .unwrap_unchecked()
        };
    } else {
        for item in keywords {
            let item_len = item.len();
            prefix[prefix_len..prefix_len + item_len].copy_from_slice(item);
            generate(
                stdout_bufwriter,
                keywords,
                prefix,
                prefix_len + item_len,
                level - 1,
            );
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
    let keywords: Vec<&str> = arguments.keyword.iter().map(String::as_str).collect();

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

    let keywords = keywords.iter().map(|k| k.as_bytes()).collect::<Vec<_>>();
    unsafe {
        let mut stdout_bufwriter = BufWriter::new(File::from_raw_fd(1));
        let mut prefix = [0u8; STRING_SIZE];
        for i in 0..=keywords.len() {
            generate(&mut stdout_bufwriter, &keywords, &mut prefix, 0, i);
        }
    }
}
