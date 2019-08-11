#ifndef CHECKM_PARSER_CPP_H
#define CHECKM_PARSER_CPP_H

#include <string>
#include <vector>

namespace checkm {
    class CheckMParser_cpp {
        public:
            CheckMParser_cpp();
            CheckMParser_cpp(std::string fileName);
            ~CheckMParser_cpp();
            void readFile();
            std::vector<std::vector<std::string> > getValues();
        private:
            std::string fileName;
            std::vector<std::vector<std::string> > records;
    };
}

#endif
