/* pythia6_dummy.c -- the user-supplied Pythia6 routines (normally from
 * libpythia6_dummy) that the LCG libpythia6.so leaves undefined.
 * GENIE never calls them; they only satisfy the linker (-Wl,--no-undefined).
 * Built by build_genie_lcg.sh when the LCG release has no libpythia6_dummy.so. */
void upinit_(void) {}
void upevnt_(void) {}
void upveto_(int *iveto) { if (iveto) *iveto = 0; }
void pyevwt_(double *wtxs) { if (wtxs) *wtxs = 1.0; }
void pykcut_(int *mcut) { if (mcut) *mcut = 0; }
void pytaud_(int *itau, int *iorig, int *kforig, int *ndecay) { (void)itau; (void)iorig; (void)kforig; if (ndecay) *ndecay = 0; }
void pytime_(int *idati) { if (idati) for (int i = 0; i < 6; i++) idati[i] = 0; }
void sugra_(void) {}
void visaje_(void) {}
void ssmssm_(void) {}
void fhsetflags_(void) {}
void fhsetpara_(void) {}
void fhhiggscorr_(void) {}
