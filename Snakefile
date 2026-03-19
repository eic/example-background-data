# Snakefile
# Convert each *.edm4eic.root -> CSV using ROOT macro inside the container,
# then zip each CSV into csv-zip/.
#
# Assumption (simple): trk_hits_to_csv.cxx is in the SAME directory where you run snakemake
# (or otherwise visible inside the container via bind + working dir).

import os
import glob

# --- Inputs / Outputs (hardcoded, no config) ---------------------------------
INPUT_DIR = "/volatile/eic/EPIC/RECO/25.10.4/epic_craterlake/Bkg_1SignalPer2usFrame/DIS/NC/10x100/minQ2=1"

OUT_BASE  = "/volatile/eic/romanov/25.10.4_bkg-1signal-2us-frame_dis-nc_10x100_minq2-1"
CSV_DIR   = f"{OUT_BASE}/csv"
ZIP_DIR   = f"{OUT_BASE}/csv-zip"
LOG_DIR   = f"{OUT_BASE}/logs"

# ROOT macro + argument
MACRO     = f"/work/eic3/users/romanov/ai-background/trk_hits_to_csv.cxx"

# Container image (Snakemake will run rules inside it when you launch with --sdm apptainer)
container: "/cvmfs/singularity.opensciencegrid.org/eicweb/eic_xl:nightly"

# --- Discover inputs ---------------------------------------------------------
inputs = sorted(glob.glob(os.path.join(INPUT_DIR, "*.edm4eic.root")))
if not inputs:
    raise ValueError(f"No *.edm4eic.root files found in: {INPUT_DIR}")

# for now process a single file
inputs = inputs[:100]

def sample_from_input(p: str) -> str:
    suf = ".edm4eic.root"
    name = os.path.basename(p)
    if not name.endswith(suf):
        raise ValueError(f"Unexpected input name: {name}")
    return name[:-len(suf)]

SAMPLES = [sample_from_input(p) for p in inputs]

# --- Workflow ----------------------------------------------------------------
rule all:
    input:
        expand(f"{ZIP_DIR}/{{sample}}.csv.zip", sample=SAMPLES)

rule hits_csv:
    input:
        root=f"{INPUT_DIR}" + "/{sample}.edm4eic.root"
    output:
        csv=f"{CSV_DIR}" + "/{sample}.csv"
    log:
        f"{LOG_DIR}" + "/{sample}.hits.log"
    threads: 1
    resources:
        mem_mb=4000,
        time_min=60
    shell:
        r"""
        set -euo pipefail
        mkdir -p "{CSV_DIR}" "{LOG_DIR}"

        echo "=== HITS CSV ===============================================">"{log}"
        echo "Input : {input.root}"                                       >> "{log}"
        echo "Output: {output.csv}"                                       >> "{log}"
        echo "Macro : {MACRO}"                                            >> "{log}"
        echo "Start : $(date)"                                            >> "{log}"
        echo "Host  : $(hostname)"                                        >> "{log}"
        echo "-----------------------------------------------------------">> "{log}"

        # Note: macro is referenced by name. Keep trk_hits_to_csv.cxx in the run directory,
        # or make sure it's visible in-container via bind.
        root -x -l -b -q "{MACRO}(\"{input.root}\",\"{output.csv}\")" >> "{log}" 2>&1

        echo "----------------------------------------------------------------" >> "{log}"
        echo "Done  : $(date)"                                            >> "{log}"
        """

rule zip_csv:
    input:
        csv=f"{CSV_DIR}" + "/{sample}.csv"
    output:
        z=f"{ZIP_DIR}" + "/{sample}.csv.zip"
    log:
        f"{LOG_DIR}" + "/{sample}.zip.log"
    threads: 1
    resources:
        mem_mb=500,
        time_min=10
    shell:
        r"""
        set -euo pipefail
        mkdir -p "{ZIP_DIR}" "{LOG_DIR}"

        echo "=== ZIP CSV =====================================================" >  "{log}"
        echo "Input : {input.csv}"                                        >> "{log}"
        echo "Output: {output.z}"                                         >> "{log}"
        echo "Start : $(date)"                                            >> "{log}"
        echo "Host  : $(hostname)"                                        >> "{log}"
        echo "----------------------------------------------------------------" >> "{log}"

        python3 -m zipfile -c "{output.z}" "{input.csv}" >> "{log}" 2>&1

        echo "----------------------------------------------------------------" >> "{log}"
        echo "Done  : $(date)"                                            >> "{log}"
        """
