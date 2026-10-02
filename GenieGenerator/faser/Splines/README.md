These scripts recalculate the splines up to 7 TeV for materials in FASER.

This will require a significant amount of CPU time (~2-3 days on a dedicated 16-core PC).

First, generate free-nucleon splines:

```
> source $GENIE/faser/Splines/calcSplinesN.sh
```

When job is finished, merge them:

```
> source $GENIE/faser/Splines/mergeSplinesN.sh
```

Then generate nuclear target splines for each neutrino flavor.

The scripts run 16 jobs for each flavor to facilitate parallel computation.

If you have a batch system, you can edit the scripts to submit batch jobs instead of running in the background.

Otherwise, it's probably a good idea to run one flavor at a time and let it finish before launching the next.

```
> source $GENIE/faser/Splines/calcNuESplinesA.sh
> source $GENIE/faser/Splines/calcNuMuSplinesA.sh
> source $GENIE/faser/Splines/calcNuTauSplinesA.sh
> source $GENIE/faser/Splines/calcAntiNuESplinesA.sh
> source $GENIE/faser/Splines/calcAntiNuMuSplinesA.sh
> source $GENIE/faser/Splines/calcAntiNuTauSplinesA.sh
```

Finally, when all jobs have finished, merge the splines into a single file:

```
> source $GENIE/faser/Splines/mergeSplinesA.sh
```
