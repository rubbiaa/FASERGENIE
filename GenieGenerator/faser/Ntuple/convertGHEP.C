void convertGHEP(const std::string& inputFilename, const std::string& outputFilename, bool ccOnly = false)
{
  // recite the incantations necessary to read Genie's ntuple

  printf("go\n");
  gSystem->Load("liblog4cpp.so");
  gSystem->Load("libEG.so");
  gROOT->ProcessLine(".L lib/libGFwUtl.so");
  gROOT->ProcessLine(".L lib/libGFwParDat.so");
  gROOT->ProcessLine(".L lib/libGFwAlg.so");
  gROOT->ProcessLine(".L lib/libGFwReg.so");
  gROOT->ProcessLine(".L lib/libGFwGHEP.so");
  using namespace genie;
  printf("opening files\n");
  TFile* inFile = TFile::Open(inputFilename.c_str(), "READ");
  TTree* inTree = (TTree*) inFile->Get("gtree");
  printf("opening files 2\n");
  NtpMCEventRecord* pRecord = nullptr;
  printf("opening files 3\n");
      std::cout << pRecord << std::endl;
      //  TBranch* b_gmcrec = inTree->GetBranch("gmcrec");
      //b_gmcrec->SetAddress(&pRecord);
      inTree -> SetBranchAddress("gmcrec",&pRecord);
      std::cout << pRecord << std::endl;
  printf("opening files 4\n");
  // set up the output tree
  
  TFile* outFile = TFile::Open(outputFilename.c_str(), "RECREATE");
  outFile->cd();
  TTree* outTree = new TTree("gFaser","gFaserTitle");

  printf("Done opening...\n");
  // buffers 

  int nFinal;
  double vx;
  double vy;
  double vz;
  // to do: add interaction information
  std::vector<std::string> name;
  std::vector<int> pdgc;
  std::vector<int> status;
  std::vector<int> firstMother;
  std::vector<int> lastMother;
  std::vector<int> firstDaughter;
  std::vector<int> lastDaughter;
  std::vector<double> px;
  std::vector<double> py;
  std::vector<double> pz;
  std::vector<double> E;
  std::vector<double> m;
  std::vector<double> M;
  
  outTree->Branch("vx",&vx,"vx/D");
  outTree->Branch("vy",&vy,"vy/D");
  outTree->Branch("vz",&vz,"vz/D");
  outTree->Branch("n",&nFinal,"n/I");
  outTree->Branch("name","std::vector<std::string>",&name);
  outTree->Branch("pdgc","std::vector<int>",&pdgc);
  outTree->Branch("status","std::vector<int>",&status);
  outTree->Branch("firstMother","std::vector<int>",&firstMother);
  outTree->Branch("lastMother","std::vector<int>",&lastMother);
  outTree->Branch("firstDaughter","std::vector<int>",&firstDaughter);
  outTree->Branch("lastDaughter","std::vector<int>",&lastDaughter);
  outTree->Branch("px","std::vector<double>",&px);
  outTree->Branch("py","std::vector<double>",&py);
  outTree->Branch("pz","std::vector<double>",&pz);
  outTree->Branch("E","std::vector<double>",&E);
  outTree->Branch("m","std::vector<double>",&m);
  outTree->Branch("M","std::vector<double>",&m);

  // now loop over the input tree and fill the output tree
  int nEntries = inTree->GetEntries();
  printf("nEntries=%d\n",nEntries);
 
  for (int i = 0; i < nEntries; i++)
  {
    if (i%100 == 0)
      std::cout << "Event: " << i+1 << std::endl;

    // Clear buffers
    nFinal = 0;
    vx = 0.0;
    vy = 0.0;
    vz = 0.0;
    name.clear();
    pdgc.clear();
    status.clear();
    firstMother.clear();
    lastMother.clear();
    firstDaughter.clear();
    lastDaughter.clear();
    px.clear();
    py.clear();
    pz.clear();
    E.clear();
    m.clear();
    M.clear();
    
    // read and fill
    inTree->GetEntry(i);
    EventRecord& event = *(pRecord->event);
    //    std::cout << event << std::endl;
    
    TLorentzVector* vertex = event.Vertex();
    vx = vertex->X();
    vy = vertex->Y();
    vz = vertex->Z();

    nFinal = event.GetEntries();

    // Check for CC if requested
    bool keep = true;
    if (ccOnly)
    {
      GHepParticle* nu = (GHepParticle*) event[0];
      uint nuPDG = abs(nu->Pdg());
      if (nFinal >= 3) 
      {
        GHepParticle* p = (GHepParticle*) event[2];
        if (abs(p->Pdg()) == nuPDG)
        {
          keep = false;
        }
        else if (nFinal >= 5)
        {
          p = (GHepParticle*) event[4];
          if (abs(p->Pdg()) == nuPDG) keep = false;
        }
      }
    }
    if (!keep) continue;
    for (int j = 0; j < nFinal; j++)
    {
      GHepParticle* p = (GHepParticle*) event[j];
      name.push_back(p->Name());
      pdgc.push_back(p->Pdg());
      status.push_back(p->Status());
      firstMother.push_back(p->FirstMother());
      lastMother.push_back(p->LastMother());
      firstDaughter.push_back(p->FirstDaughter());
      lastDaughter.push_back(p->LastDaughter());
      px.push_back(p->Px());
      py.push_back(p->Py());
      pz.push_back(p->Pz());
      E.push_back(p->E());
      m.push_back(p->Mass());
      if (p->IsOnMassShell())
      {
	M.push_back(p->Mass());
      }
      else
      {
	M.push_back(p->P4()->M());
      }
    }  // Loop over particles
    outTree->Fill();
    pRecord->Clear();

  }  //Loop over events

  outTree->Write();
  outFile->Close();
}
