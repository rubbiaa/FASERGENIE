#include "KlingFlux.C"
#include "KlingMeta.C"
void convertFlux(const char* inFile, const char* outFile)
{
    std::cout << "Translating ";
    std::cout.write(inFile, strlen(inFile));
    std::cout << " to ";
    std::cout.write(outFile, strlen(outFile));
    std::cout << " ... ";

    // Load dictionaries for genie classes
    gSystem->Load("GSimpleNtpEntry_C.so");
    gSystem->Load("GSimpleNtpMeta_C.so");

    // convert the flux tree
    KlingFlux flux { inFile, outFile };
    flux.Loop();

    // convert the meta tree
    KlingMeta meta { inFile, outFile };
    meta.Loop();

    std::cout << "done." << std::endl;
}