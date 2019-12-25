extern crate argparse;
use argparse::{ArgumentParser, Store, StoreTrue};
mod fasta_parser;

fn main() -> std::io::Result<()> {
    let mut fasta_file = String::new();
    let mut program = String::from("simplify");
    let mut header_adj = false;
    
    // Parse arguments using scoped borrows
    {
        let mut parser = ArgumentParser::new();
        parser.set_description("FastaOps - Simple operations of large fasta files");
        parser.refer(&mut program)
            .add_argument("program", Store, "Program to run. Select from: simplify")
            .required();
        parser.refer(&mut fasta_file)
                .add_argument("fasta-file", Store, "Fasta file to modify")
                .required();
        parser.refer(&mut header_adj)
                .add_option(&["-n", "--name-by-file"], StoreTrue, 
                    "Name by file instead of default name by record");
        parser.parse_args_or_exit();
    }

    // Run calling program
    let program = program.as_ref();
    match program {
        "simplify" => {
            fasta_parser::FastaParser::parse_to_std(&fasta_file, header_adj);
        },
        "get" => {
            println!("get function");
        },
        _ => {
            println!("Program {} does not exist! Select from: simplify", program);
            std::process::exit(1);
         }
    }
    // Notify Ok status
    Ok(())
}
