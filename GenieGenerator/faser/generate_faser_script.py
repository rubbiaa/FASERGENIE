# generate_faser_script.py

output_file = "run_faser.sh"
geometry_file = "$GENIE/faser/geometry_v5.gdml"
flux_file = "$GENIE/faser/Fluxes/Aki_2024/events_charm_4x4.root"
xsec_file = "$GENIE_HOME/faser_xsec/faserSplines.7TeV.xml"
output_prefix = "fasercal.Aki2024.charm"
initial_seed = 4189820
n_runs = 200

with open(output_file, "w") as f:
    f.write("#!/bin/bash\n\n")
    f.write("cd $GENIE_HOME/run\n\n")

    for i in range(n_runs):
        seed = initial_seed + i
        line = (
            f"gevgen_faser -l 1000.0 -r {i} -g {geometry_file} "
            f"-f {flux_file} --seed {seed} --cross-sections {xsec_file} "
            f"-o {output_prefix}\n"
        )
        f.write(line)

print(f"Bash script '{output_file}' has been created.")
