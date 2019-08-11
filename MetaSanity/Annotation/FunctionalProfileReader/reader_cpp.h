#ifndef READER_CPP_H
#define READER_CPP_H

#include <string>
#include <fstream>

namespace reader {
    class KoFamScanReader_cpp {
        public:
            KoFamScanReader_cpp();
            void writeSimplified(std::string, std::string, std::string, std::string);
        private:
            void getToken(std::string, std::string*);
    };

}


#endif