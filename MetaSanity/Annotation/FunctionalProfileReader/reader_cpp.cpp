#include "reader_cpp.h"
#include <iostream>
#include <algorithm>

/*
    Handles parsing kofam results file and functional profile data files
    Determines presence of complete metabolic function
    Class will be called through Cython

*/

namespace reader {
    KoFamScanReader_cpp::KoFamScanReader_cpp() {}


    void KoFamScanReader_cpp::writeSimplified(std::string kofamResFile, std::string out, std::string suffix = "", std::string header = "") {
        /*  Method saves all K##### values into object member std::set<std::string>

        */
        std::ifstream fp;
        fp.open(kofamResFile.c_str());
        std::ofstream outfile(out.c_str());
        if (header.compare("") != 0) {
            outfile << header << std::endl;
        }
        const std::string THRESHOLD_MET = "*";
        const size_t THRESHOLD_MET_SIZE = THRESHOLD_MET.size();
        std::string line;
        std::string token;
        std::string id_and_ko[2];
        // Skip first two header lines
        getline(fp, line);
        getline(fp, line);
        while(!fp.eof()) {
            getline(fp, line);
            if (line.compare(0, THRESHOLD_MET_SIZE, THRESHOLD_MET) == 0) {
                // Erase parts of line that come before KO number
                KoFamScanReader_cpp::getToken(line, id_and_ko);
                // Add to set of located KO values, as integers
                outfile << id_and_ko[0] << suffix << "\t" << id_and_ko[1] << std::endl;
            }
        }
    }

    void KoFamScanReader_cpp::getToken(std::string line, std::string* id_and_ko) {
        /*  Method parses a string for KO value (token)

        */
        unsigned int locInLine = 0;
        const unsigned int KO_LOCATION_IN_FILE = 3;
        const std::string DELIMITER = " ";
        size_t pos = line.find(DELIMITER);
        std::string token = line.substr(0, pos);
        // KO number is 3rd col around unknown amount of whitespace
        while (locInLine < KO_LOCATION_IN_FILE) {
            if (token.length() > 0) {
                locInLine += 1;
                if (locInLine == 2) id_and_ko[0] = token;
                if (locInLine == 3) break;
            }
            line.erase(0, pos + DELIMITER.length());
            pos = line.find(DELIMITER);
            token = line.substr(0, pos);
        }
        id_and_ko[1] = token;
    }

}