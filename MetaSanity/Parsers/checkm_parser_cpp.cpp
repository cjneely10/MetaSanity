#include <string>
#include <fstream>
#include "checkm_parser_cpp.h"

/*
Class CheckMParser parses the output of CheckM
CheckMParser will read file and return a vector of vector of strings

*/

namespace checkm {
    CheckMParser_cpp::CheckMParser_cpp() {
    }

    CheckMParser_cpp::CheckMParser_cpp(std::string fileName) {
        this->fileName = fileName;
    }

    CheckMParser_cpp::~CheckMParser_cpp() {}

    void CheckMParser_cpp::readFile() {
        std::ifstream file(this->fileName.c_str());
        if (!file.is_open()) {
            return;
        }
        std::string line;
        std::string token;
        const std::string delimiter = " ";
        const std::string header = "-";
        std::vector<std::string> line_data;
        size_t pos = 0;
        //Skip over first 3 lines
        getline(file, line);
        getline(file, line);
        getline(file, line);
        while (!file.eof()) {
            while ((pos = line.find(delimiter)) != std::string::npos) {
                token = line.substr(0, pos);
                // CheckM file has multiple whitespace characters to remove
                if (token.length() != 0) {
                    line_data.push_back(token);
                }
                line.erase(0, pos + delimiter.length());
            }
            this->records.push_back(line_data);
            line_data.clear();
            getline(file, line);
            // Last line is ---...
            while (line.compare(0, header.length(), header) == 0) {
                getline(file, line);
            }
        }
        file.close();
    }

    std::vector<std::vector<std::string> > CheckMParser_cpp::getValues() {
        return this->records;
    }

}
