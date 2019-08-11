#ifndef TSV_PARSER_CPP_H
#define TSV_PARSER_CPP_H

#include <string>
#include <vector>

namespace tsv {
    class TSVParser_cpp {
        public:
            TSVParser_cpp();
            TSVParser_cpp(std::string fileName, std::string delimiter);
            ~TSVParser_cpp();
            int readFile(int skipLines, std::string commentLineDelim, bool headerLine);
            std::vector<std::vector<std::string> > getValues();
            std::string getHeader();
        private:
            std::string fileName;
            std::vector<std::vector<std::string> > records;
            std::string headerLine;
            std::vector<std::string> commentLines;
            std::string delimiter;
    };
}

#endif
