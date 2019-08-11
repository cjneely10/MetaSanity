#ifndef FASTA_PARSER_CPP_H
#define FASTA_PARSER_CPP_H

#include <vector>
#include <string>
#include <fstream>

namespace fasta_parser {
    class FastaParser_cpp {
        public:
            FastaParser_cpp();
            FastaParser_cpp(std::ifstream&, std::string, std::string);
            ~FastaParser_cpp();
            std::vector<std::string> get();
            void grab(std::vector<std::string>&);
        private:
            std::ifstream* fastaFile;
            std::string delimiter;
            std::string header;
            std::string last_line;
    };
}


#endif