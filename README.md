Here’s a README-ready summary of what we’re doing, what to install with **uv**, and the **common Snakemake commands** to run it locally or on **SLURM**.

---

## What this workflow does

For every `*.edm4eic.root` file in:

`/volatile/eic/EPIC/RECO/25.10.4/epic_craterlake/Bkg_1SignalPer2usFrame/DIS/NC/10x100/minQ2=1`

1. Run ROOT macro inside the container:

```bash
root -x -l -b -q 'trk_hits_to_csv.cxx("input.edm4eic.root", "…/csv/<sample>.hits.csv", 2)'
```

Outputs:

* CSVs → `/volatile/eic/romanov/25.10.4_bkg-1signal-2us-frame_dis-nc_10x100_minq2-1/csv/`
* Logs → `/volatile/eic/romanov/25.10.4_bkg-1signal-2us-frame_dis-nc_10x100_minq2-1/logs/`

2. Zip each CSV into:

* ZIPs → `/volatile/eic/romanov/25.10.4_bkg-1signal-2us-frame_dis-nc_10x100_minq2-1/csv-zip/`

Container image (required):

* `/cvmfs/singularity.opensciencegrid.org/eicweb/eic_xl:nightly`

---

## Prerequisites

* `uv` available on the system
* `apptainer`/`singularity` available on compute nodes
* Access to `/cvmfs` and `/volatile` on nodes (and bind mount them)
* SLURM available for batch mode

---

## Install (uv)

Create a local venv and install Snakemake (+ the generic cluster executor plugin for SLURM):

```bash
rm -rf .venv
uv venv --python 3.11 .venv

uv pip install snakemake==9.14.6" snakemake-executor-plugin-cluster-generic
```

Sanity check (make sure you’re using the uv-installed Snakemake, not a module/system one):

```bash
uv run -p .venv snakemake --version
```

**Important:** always run Snakemake via `uv run …` so you don’t accidentally pick up an older `snakemake` from `PATH`.

---

## Run interactively (login node / local execution)

Dry-run (shows what would run):

```bash
uv run snakemake -n
```

Run with 8 cores, using the container + binds:

```bash
uv run snakemake --cores 8 \
  --use-singularity \
  --singularity-args "--bind /volatile:/volatile --bind /cvmfs:/cvmfs"
```

Helpful flags:

```bash
uv run snakemake --cores 8 \
  --use-singularity \
  --singularity-args "--bind /volatile:/volatile --bind /cvmfs:/cvmfs" \
  --printshellcmds --rerun-incomplete --keep-going
```

---

## Run via SLURM (recommended)

Use the **cluster-generic executor** (modern Snakemake way). This keeps SLURM submission explicit and readable.

Example:

```bash
OUT_BASE="/volatile/eic/romanov/25.10.4_bkg-1signal-2us-frame_dis-nc_10x100_minq2-1"
LOGS="${OUT_BASE}/logs"
mkdir -p "$LOGS"

uv run snakemake \
  --executor cluster-generic --jobs 2000 \
  --cluster-generic-submit-cmd "sbatch \
    --account=eic \
    --partition=production \
    --cpus-per-task={threads} \
    --mem=4000 \
    --time=01:00:00 \
    --output=${LOGS}/slurm-%j.out \
    --error=${LOGS}/slurm-%j.err" \
  --use-singularity \
  --singularity-args "--bind /volatile:/volatile --bind /cvmfs:/cvmfs"
```

Notes:

* `-j 200` controls how many jobs Snakemake may have in-flight (queued/running).
* `{threads}` comes from `threads:` in your Snakefile rules.

---

## Files

* `Snakefile` contains:

  * discovery of `*.edm4eic.root`
  * rule to produce CSV per input
  * rule to zip each CSV
  * `container: "/cvmfs/.../eic_xl:nightly"`

* Keep `trk_hits_to_csv.cxx` in the workflow directory (or ensure it’s visible inside the container via binds).

---
