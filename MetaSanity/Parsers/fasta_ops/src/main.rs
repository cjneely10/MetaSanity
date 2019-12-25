// use std::io::{BufRead, BufReader};
extern crate argparse;
use argparse::{ArgumentParser, Store, StoreTrue};
mod fasta_parser;

fn main() -> std::io::Result<()> {
    let mut fasta_file = String::new();
    let mut header_adj = false;
    
    // Parse arguments using scoped borrows
    {
        let mut parser = ArgumentParser::new();
        parser.set_description("FastaOps - Simple operations of large fasta files");
        parser.refer(&mut fasta_file)
                .add_argument("fasta-file", Store, "Fasta file to modify")
                .required();
        parser.refer(&mut header_adj)
                .add_option(&["-n", "--name-by-file"], StoreTrue, 
                    "Name by file instead of default name by record");
        parser.parse_args_or_exit();
    }

    // Confirm that header replace type is valid
    // let possible_types = ["file".to_string(), "record".to_string()];
    // if !possible_types.contains(&header_adj) { 
    //     println!("Incorrect header parse type");
    //     std::process::exit(1);
    // }

    fasta_parser::FastaParser::parse_to_std(&fasta_file, header_adj);

    // // Determine file basename if needed
    // // Provide counter for indexing file
    // let ff = fasta_file.clone();
    // let mut counter = 0;
    // let mut file_header : Option<&str> = None;
    // if header_adj == "file" { 
    //     file_header = std::path::Path::new(&ff).file_stem().and_then(std::ffi::OsStr::to_str);
    // }

    // // let fp = fasta_parser::FastaParser::new(fasta_file, file_header);

    // // File reader variables for parsing into 80 char chunks
    // let mut line_loc: usize = 0;
    // let mut end_of_line: bool = false;
    // let reader = BufReader::new(std::fs::File::open(fasta_file).unwrap());

    // // Parse line by line
    // for line in reader.lines() {
    //     let line = line.expect("Unable to read line");
    //     let _line = line.as_bytes();
    //     if _line.len() > 0 {
    //         // Based on first character of each line
    //         match _line[0] {
    //             // Write fasta header
    //             b'>' => {
    //                 // Based on name of file
    //                 if file_header != None {
    //                     println!(">{}_{}", file_header.unwrap(), counter);
    //                     counter += 1;
    //                 }
    //                 // Based on record
    //                 else {
    //                     write_header(&_line);
    //                 }
    //             },
    //             // Write line in 80 character segments
    //             _ => print_line_to_80(&_line, &mut line_loc, &mut end_of_line)
    //         };
    //     }
    // }
    Ok(())
}

// /// Calls print for 80 char line segments
// /// Builds passed buffer and writes once it is 80 chars long
// fn print_line_to_80(line: &[u8], line_loc: &mut usize, end_of_line: &mut bool) {
//     for (i, &item) in line.iter().enumerate() {
//         if item != b'\n' {
//             // Record to write and line available
//             if *line_loc < 80 {         
//                 print!("{}", item as char);
//                 *line_loc += 1;
//             }
//             // Record to write, line unavailable
//             else {
//                 print!("\n");
//                 *line_loc = 0;
//                 // Recursive call for remaining length of line
//                 print_line_to_80(&line[i..], line_loc, end_of_line);
//                 break;
//             }
//         }
//     }
//     // Print end of line
//     print!("\n");
//     // Update location in line to be at beginning of buffer
//     *line_loc = 0;
// }

// /// Returns up to the first space in the header
// fn write_header<'a>(line: &'a [u8]) {
//     let mut line_len = line.len();
//     for (i, &item) in line.iter().enumerate() {
//         // Identify location of space, if present, and break
//         if item == b' ' {
//             line_len = i;
//             break;
//         }
//     }
//     // Print up to space, or length of line, if short enough
//     if line_len <= 20 { 
//         println!("{}", std::str::from_utf8(&line[0..line_len]).unwrap());
//     }
//     // Print only first 12 and last 8 chars of line for max 20
//     else { 
//         print!("{}", std::str::from_utf8(&line[..12]).unwrap());
//         println!("{}", std::str::from_utf8(&line[line_len - 9..]).unwrap());
//     }
// }
