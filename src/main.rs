const ITEMS: &[&str] = &["a", "b", "c", "d", "e", "f", "g", "h", "i"];

fn generate(level: usize, max_level: usize, prefix: &str) {
    if level == 0 {
        println!("{}", prefix);
    } else {
        for i in 0..ITEMS.len() {
            generate(level - 1, max_level, &(prefix.to_owned() + ITEMS[i]));
        }
    }
}

fn main() {
    for level in 0..=ITEMS.len() {
        generate(level, ITEMS.len(), "");
    }
}
