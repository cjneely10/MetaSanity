use std::io::{BufRead, BufReader};
extern crate argparse;
use argparse::ArgumentParser;

fn main() {
    let args: Vec<String> = std::env::args().collect();

    if args.len() < 2 {
        println!("Usage: <program-name> <file>");
        std::process::exit(1);
    }
    let mut line_loc: usize = 0;
    let mut end_of_line: bool = false;
    let reader = BufReader::new(std::fs::File::open(&args[1]).unwrap());

    for line in reader.lines() {
        let line = line.expect("Unable to read line");
        let _line = line.as_bytes();
        if _line.len() > 0 {
            match _line[0] {
                b'>' => {
                    if end_of_line { 
                        print!("{}", '\n');
                        line_loc = 0;
                        end_of_line = false;
                    }
                    println!("{}", get_header(&_line));
                },
                _ => print_line_to_80(&_line, &mut line_loc, &mut end_of_line)
            };
        }
    }
}

// /// Calls print for 80 char line segments
// /// Builds passed buffer and writes once it is 80 chars long
fn print_line_to_80(line: &[u8], line_loc: &mut usize, end_of_line: &mut bool) {
    for (i, &item) in line.iter().enumerate() {
        if item != b'\n' {
            // Record to write and line available
            if *line_loc < 80 {         
                print!("{}", item as char);
                *line_loc  = *line_loc + 1;
            }
            // Record to write, line unavailable
            else {
                print!("{}", '\n');
                *line_loc = 0;
                print_line_to_80(&line[i..], line_loc, end_of_line);
                break;
            }
        }
    }
    *end_of_line = true;
}

/// Returns up to the first space in the header
fn get_header(line: &[u8]) -> &str {
    for (i, &item) in line.iter().enumerate() {
        if item == b' ' {
            return std::str::from_utf8(&line[0..i]).unwrap();
        }
    }
    std::str::from_utf8(&line[..]).unwrap()
}
