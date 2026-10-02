{
    #include <vector>
    #include <utility>
    #include <math.h>

    TFile* f = TFile::Open("Kling_2021.root", "RECREATE");
    std::vector<std::pair< string, TGraph*> > graphs {};
    graphs.push_back(std::pair {"NuE", new TGraph("Tables/NuE.txt")});
    graphs.push_back(std::pair {"NuMu", new TGraph("Tables/NuMu.txt")});
    graphs.push_back(std::pair {"NuTau", new TGraph("Tables/NuTau.txt")});
    graphs.push_back(std::pair {"AntiNuE", new TGraph("Tables/AntiNuE.txt")});
    graphs.push_back(std::pair {"AntiNuMu", new TGraph("Tables/AntiNuMu.txt")});
    graphs.push_back(std::pair {"AntiNuTau", new TGraph("Tables/AntiNuTau.txt")});

    // Felix's tables are y = dN/bin, where bins are 1/10 of a decade of energy
    // Genie needs a histogram of dN/dE = y * 10/(E ln 10)
    // Do a cubic spline interpolation of y and fill a histogram of dN/dE(GeV) with equal bin widths
    // Note that to integrate the flux, the resulting histograms should be multiplied by the bin width before summing
    // (i.e. they are dN/dE, not dN/bin)
    // We also divide by the assumed area of 25x25 = 625 cm^2 
    // to get the number of neutrinos per cm^2/GeV/(150 fb^-1)

    // const size_t nBins = 1000;
    const double nBinsPerGev = 2.0;
    const double area = 625.0; // cm^2

    for (auto p : graphs)
    {
        string name = p.first;
        TGraph* graph = p.second;
        graph->SetBit(TGraph::kIsSortedX);
        auto binEdges = graph->GetX();
        auto values = graph->GetY();
        auto binWidthOrig = (log(binEdges[graph->GetN()-1])/log(10.0)-log(binEdges[0])/log(10.0))/(graph->GetN()-1);
        auto minE = pow(10.0,log(binEdges[0])/log(10.0)-binWidthOrig/2);
        auto maxE = pow(10.0,log(binEdges[graph->GetN()-1])/log(10.0)+binWidthOrig/2);
        std::cout << "min, max energy limits: " << minE << ", " << maxE << std::endl;
        Int_t nBins = nBinsPerGev*(ceil(maxE)-floor(minE));
        auto binWidth = 1/nBinsPerGev;

        TH1F* hist = new TH1F(name.c_str(), name.c_str(), nBins, floor(minE), ceil(maxE));


        for (size_t iBin = 0; iBin < nBins; iBin++)
        {
            auto center = floor(minE) + binWidth/2 + iBin * binWidth;
            auto y = max(0.0, graph->Eval(center, nullptr, "S")/area);
            hist->SetBinContent(iBin+1, y * 10.0 / (center * log(10.0)));
        }

        hist->Write();
        delete graph;
        p.second = nullptr;     
    }
    f->Close();
}