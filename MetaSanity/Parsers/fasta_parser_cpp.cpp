#include <string>
#include <fstream>
#include <algorithm>
#include <iostream>
#include "fasta_parser_cpp.h"
//#include "rope.cpp"


/*
Class will parse fasta and return vector string arrays, indices are fasta id,
remaining header values, and fasta record

*/

namespace fasta_parser {
    FastaParser_cpp::FastaParser_cpp() {}

    FastaParser_cpp::FastaParser_cpp(std::ifstream& f, std::string delim = " ",
                std::string head = ">") {
        fastaFile = &f;
        delimiter = delim;
        header = head;
        last_line = "";
    }

    FastaParser_cpp::~FastaParser_cpp() {}

    void FastaParser_cpp::grab(std::vector<std::string>& line_data) {
        std::string line;
        std::string *longLine = new std::string;
        if (line_data.size() > 0) {
            line_data.clear();
        }
        size_t pos = 0;
        if (!(*this->fastaFile).eof()) {
            if (this->last_line != "") {
                line = this->last_line;
            }
            while (line.compare(0, this->header.length(), this->header) != 0 && !(*this->fastaFile).eof()) {
                getline((*this->fastaFile), line);
            }
            pos = line.find(this->delimiter);
            if (static_cast<int>(pos) == -1) {
                line_data.push_back(line.substr(1));
                line_data.push_back("");
            } else {
                line_data.push_back(line.substr(1, pos - 1));
                line_data.push_back(line.substr(pos + 1, line.length()));
            }
            getline((*this->fastaFile), line);
            line.erase(std::remove(line.begin(), line.end(), '\r'), line.end());
            while (line.compare(0, this->header.length(), this->header) != 0 && !(*this->fastaFile).eof()) {
                longLine->append(line);
                getline((*this->fastaFile), line);
                line.erase(std::remove(line.begin(), line.end(), '\r'), line.end());
            }
            line_data.push_back(*longLine);
            this->last_line = line;
        }
        delete longLine;
    }

}
