#include <string>
#include <vector>
#include <fstream>
#include "tsv_parser_cpp.h"

/*
Class CheckMParser parses the output of CheckM
CheckMParser will read file and return a vector of vector of strings

*/

namespace tsv {
    TSVParser_cpp::TSVParser_cpp() {
    }

    TSVParser_cpp::TSVParser_cpp(std::string fileName, std::string delimiter = "\t") {
        this->fileName = fileName;
        this->headerLine = "";
        this->delimiter = delimiter;
    }

    TSVParser_cpp::~TSVParser_cpp() { }

    int TSVParser_cpp::readFile(int skipLines = 0, std::string commentLineDelim = "#", bool headerLine = false) {
        std::ifstream file(this->fileName.c_str());
        if (!file.is_open()) {
            return 1;
        }
        std::string line;
        std::string token;
        std::vector<std::string> line_data;
        size_t pos = 0;
        // Skip over first n lines
        if (skipLines > 0) {
        for (int i = 0; i < skipLines; ++i) {
            getline(file, line);
        }
        }
        getline(file, line);
        // Store header line and move past
        if (headerLine) {
            this->headerLine = line;
            getline(file, line);
        }
        while (!file.eof()) {
            // Store comment lines
            if (line.compare(0, commentLineDelim.length(), commentLineDelim) == 0) {
                this->commentLines.push_back(line);
                getline(file, line);
            }
            while ((pos = line.find(this->delimiter)) != std::string::npos) {
                token = line.substr(0, pos);
                line_data.push_back(token);
                line.erase(0, pos + this->delimiter.length());
            }
            // Store final value
            token = line.substr(0, pos);
            line_data.push_back(token);
            this->records.push_back(line_data);

            line_data.clear();
            getline(file, line);
        }
        file.close();
        return 0;
    }

    std::vector<std::vector<std::string> > TSVParser_cpp::getValues() {
        return this->records;
    }

    std::string TSVParser_cpp::getHeader() {
        return this->headerLine;
    }

}
