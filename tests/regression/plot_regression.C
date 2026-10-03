// plot_regression.C -- draw the regression histograms written by run_regression.py
//
//   root -l -b -q 'plot_regression.C("current.hists.txt","golden.hists.txt","out.pdf","title")'
//   root -l -b -q 'plot_regression.C("golden.hists.txt","-","golden.pdf","golden light")'
//
// Text format, one histogram per line:
//   name|title|xtitle|logx|label1;label2;...(or -)|edge0,edge1,...|under,bin1,...,binN,over
// With a golden file: golden (grey band, normalized to the current number of
// entries) and current (points), plus the chi2 shape-test p-value and a
// current/golden ratio pad. Also writes the histograms as TH1D into
// <out>.root (same name as the PDF).
#include <cmath>
#include <TCanvas.h>
#include <TFile.h>
#include <TH1D.h>
#include <TLatex.h>
#include <TLegend.h>
#include <TPad.h>
#include <TStyle.h>
#include <TString.h>
#include <TSystem.h>
#include <fstream>
#include <map>
#include <sstream>
#include <string>
#include <vector>

namespace {
std::vector<std::string> split(const std::string& s, char sep)
{
  std::vector<std::string> out; std::string cur; std::stringstream ss(s);
  while (std::getline(ss, cur, sep)) out.push_back(cur);
  if (!s.empty() && s.back() == sep) out.push_back("");
  return out;
}

struct HDef { std::string name; TH1D* h; bool logx; };

std::vector<HDef> readHists(const std::string& file, const std::string& tagname)
{
  std::vector<HDef> out;
  std::ifstream in(file);
  std::string line;
  while (std::getline(in, line)) {
    std::vector<std::string> f = split(line, '|');
    if (f.size() < 7) continue;
    std::vector<std::string> es = split(f[5], ','), cs = split(f[6], ',');
    std::vector<double> edges;
    for (auto& e : es) edges.push_back(atof(e.c_str()));
    int nb = (int)edges.size() - 1;
    if (nb < 1 || (int)cs.size() != nb + 2) continue;
    TString hname = TString::Format("%s_%s", f[0].c_str(), tagname.c_str());
    TH1D* h = new TH1D(hname, TString::Format("%s;%s;events", f[1].c_str(),
                       f[2] == "-" ? "" : f[2].c_str()), nb, edges.data());
    h->SetDirectory(nullptr);
    for (int i = 0; i < nb + 2; i++) {
      double c = atof(cs[i].c_str());
      h->SetBinContent(i, c);
      h->SetBinError(i, std::sqrt(c));
    }
    h->SetEntries(h->Integral(0, nb + 1));
    if (f[4] != "-") {
      std::vector<std::string> labels = split(f[4], ';');
      for (int i = 0; i < nb && i < (int)labels.size(); i++)
        h->GetXaxis()->SetBinLabel(i + 1, labels[i].c_str());
    }
    out.push_back({f[0], h, f[3] == "1"});
  }
  return out;
}
}  // namespace

int plot_regression(const char* currentFile, const char* goldenFile, const char* pdf,
                    const char* title = "")
{
  gStyle->SetOptStat(0);
  gStyle->SetPaperSize(30., 20.);           // landscape page matching the 3:2 canvas
  gStyle->SetTitleFontSize(0.07);
  std::vector<HDef> cur = readHists(currentFile, "current");
  std::vector<HDef> gold;
  bool haveGold = std::string(goldenFile) != "-";
  if (haveGold) gold = readHists(goldenFile, "golden");
  std::map<std::string, TH1D*> goldMap;
  for (auto& g : gold) goldMap[g.name] = g.h;
  if (cur.empty()) { printf("plot_regression: no histograms in %s\n", currentFile); return 1; }

  TString out(pdf);
  TString rootOut = out; rootOut.ReplaceAll(".pdf", ".root");
  TFile fout(rootOut, "RECREATE");

  TCanvas c("c", "c", 1200, 800);
  const int perPage = 6;
  int nPages = (cur.size() + perPage - 1) / perPage;
  for (int page = 0; page < nPages; page++) {
    c.Clear();
    c.Divide(3, 2);
    for (int k = 0; k < perPage; k++) {
      size_t i = page * perPage + k;
      if (i >= cur.size()) break;
      TH1D* h = cur[i].h;
      TVirtualPad* cell = c.cd(k + 1);
      TPad* top = nullptr; TPad* bot = nullptr;
      TH1D* g = haveGold && goldMap.count(cur[i].name) ? goldMap[cur[i].name] : nullptr;
      if (g) {
        top = new TPad(TString::Format("t%zu", i), "", 0, 0.3, 1, 1);
        bot = new TPad(TString::Format("b%zu", i), "", 0, 0, 1, 0.3);
        top->SetBottomMargin(0.02); bot->SetTopMargin(0.02); bot->SetBottomMargin(0.3);
        top->Draw(); bot->Draw();
        top->cd();
      }
      if (cur[i].logx) gPad->SetLogx();
      h->SetMarkerStyle(20); h->SetMarkerSize(0.5); h->SetLineColor(kBlue + 1);
      h->SetMarkerColor(kBlue + 1);
      double ymax = h->GetMaximum();
      TH1D* gs = nullptr;
      if (g) {
        gs = (TH1D*) g->Clone(TString::Format("%s_scaled", g->GetName()));
        double sc = g->Integral(0, g->GetNbinsX() + 1) > 0
                        ? h->Integral(0, h->GetNbinsX() + 1) / g->Integral(0, g->GetNbinsX() + 1) : 1;
        gs->Scale(sc);
        gs->SetFillColor(kGray); gs->SetLineColor(kGray + 2); gs->SetMarkerSize(0);
        ymax = std::max(ymax, gs->GetMaximum());
        gs->SetMaximum(1.25 * ymax + 1); gs->SetMinimum(0);
        gs->SetTitle(h->GetTitle());
        gs->GetXaxis()->SetLabelSize(0);
        gs->Draw("E2");
        h->Draw("E1 same");
        TLatex lt; lt.SetNDC(); lt.SetTextSize(0.06);
        if (g->Integral() < 20 && h->Integral() < 20) {
          lt.SetTextColor(kGray + 2);
          lt.DrawLatex(0.55, 0.82, "too few entries");
        } else {
          double p = g->Chi2Test(h, "UU");
          lt.SetTextColor(p < 1e-4 ? kRed : (p < 1e-2 ? kOrange + 7 : kGreen + 2));
          lt.DrawLatex(0.55, 0.82, TString::Format("#chi^{2} p = %.3g", p));
        }
        TLegend* leg = new TLegend(0.55, 0.62, 0.89, 0.78);
        leg->SetBorderSize(0); leg->SetFillStyle(0); leg->SetTextSize(0.05);
        leg->AddEntry(gs, "golden", "f"); leg->AddEntry(h, "current", "lep");
        leg->Draw();
        bot->cd();
        if (cur[i].logx) gPad->SetLogx();
        TH1D* r = (TH1D*) h->Clone(TString::Format("%s_ratio", h->GetName()));
        r->Divide(gs);
        r->SetTitle(TString::Format(";%s;cur/gold", h->GetXaxis()->GetTitle()));
        r->SetMinimum(0.5); r->SetMaximum(1.5);
        r->GetYaxis()->SetNdivisions(503); r->GetYaxis()->SetLabelSize(0.1);
        r->GetYaxis()->SetTitleSize(0.1); r->GetYaxis()->SetTitleOffset(0.4);
        r->GetXaxis()->SetLabelSize(0.11); r->GetXaxis()->SetTitleSize(0.11);
        r->Draw("E1");
        cell->cd();
        fout.cd(); g->Write();
      } else {
        h->SetFillColor(kAzure - 9);
        h->SetMinimum(0); h->SetMaximum(1.25 * ymax + 1);
        h->Draw("HIST");
        h->Draw("E1 same");
      }
      fout.cd(); h->Write();
    }
    TString name = out;
    if (nPages > 1) name += (page == 0 ? "(" : (page == nPages - 1 ? ")" : ""));
    c.Print(name, TString::Format("Title:%s", title));
  }
  fout.Close();
  return 0;
}
