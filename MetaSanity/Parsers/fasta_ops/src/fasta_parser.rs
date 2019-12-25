use std::io::{BufRead, BufReader};

pub struct FastaParser {
    fasta_file: String,
    file_header: Option<String>,
    record_locations: Option<std::collections::HashMap<String, u16>>
}

impl FastaParser {
    pub fn parse_to_std(fasta_file: &str, header_as_id: bool) {
        let fp = FastaParser::new(fasta_file, header_as_id);
        fp.write_simple();
    }

    pub fn new(fasta_file: &str, header_as_id: bool) -> FastaParser {
        let mut file_header: Option<String> = None;
        if header_as_id {
            file_header = Some(
                String::from(
                    std::path::Path::new(&fasta_file)
                        .file_stem()
                        .and_then(std::ffi::OsStr::to_str)
                        .unwrap()
                )
            );
        }
        // Confirm file exists
        if !std::path::Path::new(&fasta_file).exists() {
            println!("Fasta file {} does not exist!", fasta_file);
            std::process::exit(1);
        }
        // Return parsed object
        FastaParser{
            fasta_file: fasta_file.to_string(),
            file_header: file_header,
            record_locations: Some(std::collections::HashMap::new())
        }
    }

    fn write_simple(&self) {
        // File reader variables for parsing into 80 char chunks
        let mut line_loc: usize = 0;
        let mut end_of_line: bool = false;
        let mut counter: u16 = 0;
        let reader = BufReader::new(std::fs::File::open(self.fasta_file.clone()).unwrap());

        // Parse line by line
        for line in reader.lines() {
            let line = line.expect("Unable to read line");
            let _line = line.as_bytes();
            if _line.len() > 0 {
                // Based on first character of each line
                match _line[0] {
                    // Write fasta header
                    b'>' => {
                        // Based on name of file
                        match self.file_header.as_ref() {
                            None => {
                                self.write_header(&_line);
                            }
                            Some(header) => {
                                println!(">{}_{}", header, counter);
                                counter += 1;
                            }
                        }
                    },
                    // Write line in 80 character segments
                    _ => self.print_line_to_80(&_line, &mut line_loc, &mut end_of_line)
                };
            }
        }
    }

    /// Calls print for 80 char line segments
    /// Builds passed buffer and writes once it is 80 chars long
    fn print_line_to_80(&self, line: &[u8], line_loc: &mut usize, end_of_line: &mut bool) {
        for (i, &item) in line.iter().enumerate() {
            if item != b'\n' {
                // Record to write and line available
                if *line_loc < 80 {         
                    print!("{}", item as char);
                    *line_loc += 1;
                }
                // Record to write, line unavailable
                else {
                    print!("\n");
                    *line_loc = 0;
                    // Recursive call for remaining length of line
                    self.print_line_to_80(&line[i..], line_loc, end_of_line);
                    break;
                }
            }
        }
        // Print end of line
        print!("\n");
        // Update location in line to be at beginning of buffer
        *line_loc = 0;
    }
    
    /// Returns up to the first space in the header
    fn write_header<'a>(&self, line: &'a [u8]) {
        let mut line_len = line.len();
        for (i, &item) in line.iter().enumerate() {
            // Identify location of space, if present, and break
            if item == b' ' {
                line_len = i;
                break;
            }
        }
        // Print up to space, or length of line, if short enough
        if line_len <= 20 { 
            println!("{}", std::str::from_utf8(&line[0..line_len]).unwrap());
        }
        // Print only first 12 and last 8 chars of line for max 20
        else { 
            print!("{}", std::str::from_utf8(&line[..12]).unwrap());
            println!("{}", std::str::from_utf8(&line[line_len - 9..]).unwrap());
        }
    }
}
