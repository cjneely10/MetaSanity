use std::io::{BufRead, BufReader};

pub struct FastaParser {
    pub fasta_file: String,
    file_header: Option<String>,
    record_locations: Option<std::collections::HashMap<String, LineNum>>
}

#[derive(Debug)]
struct LineNum {
    start: usize,
    end: usize
}

impl FastaParser {
    /// Initializer for FastaParser object
    /// * Assumes that the file has already been parsed to standard
    /// * Will run even if not adequately parsed
    pub fn new(fasta_file: &str, header_as_id: bool) -> FastaParser {
        // Confirm file exists
        if !std::path::Path::new(&fasta_file).exists() {
            println!("Fasta file {} does not exist!", fasta_file);
            std::process::exit(1);
        }
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
        // Return parsed object
        let mut fp = FastaParser{
            fasta_file: fasta_file.to_string(),
            file_header: file_header,
            record_locations: None
        };
        fp.record_locations = fp.generate_index_map();
        fp
    }

    /// Creates an index of the line numbers within the fasta file
    /// * Used for quick access by id
    fn generate_index_map(&self) -> Option<std::collections::HashMap<String, LineNum>> {
        let reader = BufReader::new(std::fs::File::open(self.fasta_file.clone()).unwrap());
        let mut counter: u16 = 0;
        let mut old_count = counter;
        let mut header = String::new();
        let mut index_hash: std::collections::HashMap<String, LineNum> = std::collections::HashMap::new();

        for line in reader.lines() {
            let line = line.expect("Unable to read line");
            let _line = line.as_bytes();
            // Update line count
            counter += 1;
            if _line[0] == b'>' {
                // Store initial header line
                if old_count == 0 { 
                    header = String::from(&line[1..]);
                    old_count = 1;
                };
                // Store in hash map based on id (gathered from last record)
                index_hash.insert(
                    header.clone(),
                    LineNum{start: old_count as usize - 1, end: counter as usize - 2}
                );
                // Store new count as end of section
                old_count = counter;
                // Update new header id
                header = String::from(&line[1..]);
            }
        }
        Some(index_hash)
    }

    /// Public method for returning a specific id
    pub fn get(&self, fasta_id: &str) {
        let file = BufReader::new(std::fs::File::open(self.fasta_file.clone()).unwrap());
        let location = self.record_locations
            .as_ref()
            .unwrap()
            .get(fasta_id).expect("Unable to locate ID");
        // Print out lines that correspond to the location
        for (i, line) in file.lines().enumerate() {
            if i >= location.start && i <= location.end {
                let line = line.expect("Unable to read line");
                println!("{}", line);
            }
        }
    }

    /// Method outputs FASTA file to stdout in std format
    pub fn parse_to_std(fasta_file: &str, header_as_id: bool) {
        FastaParser::new(fasta_file, header_as_id).write_simple();
    }

    /// Writes FASTA file to standard format
    /// * Outputs to stdout
    pub fn write_simple(&self) {
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
    /// * Builds passed buffer and writes once it is 80 chars long
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
